require 'sim_launcher'
require 'json'
require 'net/http'
require 'cfpropertylist'
require 'calabash-cucumber/utils/logging'
require 'run_loop'

module Calabash
  module Cucumber

    # Acts as a bridge to the sim_launcher SimLauncher and SdkDetector classes.
    #
    # Runtime Environmental Variables
    #
    # * `PROJECT_DIR` (ENV['PWD']) - the path to the .xcproject directory
    # * `DEVICE_ENDPOINT` (http://localhost:37265/) - the ip:port of the
    #   device under test
    # * `CALABASH_VERSION_PATH` (version) - the path to server version route
    # * `MAX_CONNECT_RETRY` (2) the number of times retry
    #   establishing a connection to the server.
    # * `CONNECT_TIMEOUT` (30) how long to wait for the server before timing
    #   out
    #
    class SimulatorLauncher
      include Calabash::Cucumber::Logging

      # Custom error indicating a timeout in launching and connecting to the
      # embedded calabash server.
      # @todo This is duplicated in Launcher class - consider errors.rb module.
      class TimeoutErr < RuntimeError
      end

      # @!visibility private
      # The file path to the default Xcode DerivedData directory.
      DERIVED_DATA = File.expand_path('~/Library/Developer/Xcode/DerivedData')

      # @!visibility private]
      # The file path to the default Xcode preferences plist.
      XCODE_PREFS = File.expand_path('~/Library/Preferences/com.apple.dt.Xcode.plist')

      # @!visibility private
      # REGEX for finding application Info.plist.
      DEFAULT_DERIVED_DATA_INFO = File.expand_path("#{DERIVED_DATA}/*/info.plist")

      # @!visibility private
      # If `CONNECT_TIMEOUT` is not set, wait this long for the app to launch
      # in the simulator before retrying.
      DEFAULT_SIM_WAIT = 30

      # If `MAX_CONNECT_RETRY` is not set, try to launch the app this many times
      # in the simulator before giving up
      DEFAULT_SIM_RETRY = 2

      # @!visibility private
      # An instance of Calabash::Cucumber::Device.
      attr_accessor :device

      # @!visibility private
      # An instance of SimLauncher::Simulator.
      attr_accessor :simulator

      # @!visibility private
      # An instance of SimLauncher::SdkDetector.
      attr_accessor :sdk_detector

      # @!visibility private
      # The launch args passed from Calabash::Cucumber::Launcher to the launch
      # and relaunch methods.
      attr_accessor :launch_args

      # Creates a new instance an sets the :simulator and :sdk_detector attributes.
      def initialize
        @simulator = SimLauncher::Simulator.new
        @sdk_detector = SimLauncher::SdkDetector.new()
      end

      # Stops (quits) the simulator.
      def stop
        RunLoop::SimControl.new.quit_sim
      end


      # @!visibility private
      # Uses heuristics to deduce the derived data directory for the project
      # so the path to the app bundle (.app) can be detected.
      # @return [String] absolute path to derived data directory
      # @raise [RuntimeError] if the derived data directory cannot be found
      def derived_data_dir_for_project
        dir = project_dir
        xcode_workspace_name = ''
        info_plist = Dir.glob(DEFAULT_DERIVED_DATA_INFO).find { |plist_file|
          begin
            plist = CFPropertyList::List.new(:file => plist_file)
            hash = CFPropertyList.native_types(plist.value)
            ws_dir = File.dirname(hash['WorkspacePath']).downcase
            p_dir = dir.downcase
            if p_dir.include? ws_dir
              xcode_workspace_name = ws_dir.split('/').last
            end
            ws_dir == p_dir
          rescue
            false
          end
        }

        return File.dirname(info_plist) unless info_plist.nil?

        res = Dir.glob("#{dir}/*.xcodeproj")
        if res.empty?
          raise "Unable to find *.xcodeproj in #{dir}"
        elsif res.count > 1
          raise "Unable to found several *.xcodeproj in #{dir}: #{res}"
        end

        xcode_proj_name = res.first.split('.xcodeproj')[0]

        xcode_proj_name = File.basename(xcode_proj_name)

        build_dirs = Dir.glob("#{DERIVED_DATA}/*").find_all do |xc_proj|
          File.basename(xc_proj).start_with?(xcode_proj_name)
        end

        if build_dirs.count == 0 && !xcode_workspace_name.empty?
          # check for directory named "workspace-{deriveddirectoryrandomcharacters}"
          build_dirs = Dir.glob("#{DERIVED_DATA}/*").find_all do |xc_proj|
            File.basename(xc_proj).downcase.start_with?(xcode_workspace_name)
          end
        end

        # todo analyze `derived_data_dir_for_project` to see if it contains dead code
        # todo assuming this is not dead code, the documentation around derived data for project needs to be updated

        if build_dirs.count == 0
          msg = ['Unable to find your built app.']
          msg << "This means that Calabash can't automatically launch iOS simulator."
          msg << "Searched in Xcode 4.x default: #{DEFAULT_DERIVED_DATA_INFO}"
          msg << ''
          msg << "To fix there are a couple of options:\n"
          msg << 'Option 1) Make sure you are running this command from your project directory, '
          msg << 'i.e., the directory containing your .xcodeproj file.'
          msg << 'In Xcode, build your calabash target for simulator.'
          msg << "Check that your app can be found in\n #{DERIVED_DATA}"
          msg << "\n\nOption 2). In features/support/01_launch.rb set APP_BUNDLE_PATH to"
          msg << 'the path where Xcode has built your Calabash target.'
          msg << "Alternatively you can use the environment variable APP_BUNDLE_PATH.\n"
          raise msg.join("\n")

        elsif build_dirs.count > 1
          msg = ['Unable to auto detect APP_BUNDLE_PATH.']
          msg << "You have several projects with the same name: #{xcode_proj_name} in #{DERIVED_DATA}:\n"
          msg << build_dirs.join("\n")

          msg << "\nThis means that Calabash can't automatically launch iOS simulator."
          msg << "Searched in Xcode 4.x default: #{DEFAULT_DERIVED_DATA_INFO}"
          msg << "\nIn features/support/01_launch.rb set APP_BUNDLE_PATH to"
          msg << 'the path where Xcode has built your Calabash target.'
          msg << "Alternatively you can use the environment variable APP_BUNDLE_PATH.\n"
          raise msg.join("\n")
        else
          if full_console_logging?
            puts "Found potential build dir: #{build_dirs.first}"
            puts 'Checking...'
          end
          build_dirs.first
        end
      end

      # @!visibility private
      # Returns the absolute build path to the project directory.
      #
      # @return [String] absolute path to the projects build directory
      def build_output_dir_for_project
        xcode_temp_prefs = File.join(project_dir, '.cal_xcode_prefs')
        FileUtils.cp(XCODE_PREFS, xcode_temp_prefs)
        `plutil -convert xml1 "#{xcode_temp_prefs}"`

        plist = CFPropertyList::List.new(:file => xcode_temp_prefs)
        hash = CFPropertyList.native_types(plist.value)

        if hash.has_key?('IDESharedBuildFolderName')
          build_folder_name = hash['IDESharedBuildFolderName']
          output_dir = "#{DERIVED_DATA}/#{build_folder_name}/Products"
        elsif hash.has_key?('IDECustomBuildProductsPath')
          products_path = hash['IDECustomBuildProductsPath']
          File.join(project_dir, products_path)
        else
          output_dir = derived_data_dir_for_project
        end

        FileUtils.rm(xcode_temp_prefs)

        output_dir
      end

      # @!visibility private
      # Returns the absolute path to the project directory.
      #
      # Unless `PROJECT_DIR` is defined, returns the absolute path to the current
      # directory.
      #
      # @return [String] absolute path to the project directory
      # @todo migrate `PROJECT_DIR` to environment_helpers.rb
      def project_dir
        File.expand_path(ENV['PROJECT_DIR'] || Dir.pwd)
      end

      # @!visibility private
      # Attempts to deduce the app bundle path
      # @param [String] path NEEDS DOCUMENTATION
      # @param [String] device_build_dir NEEDS DOCUMENTATION
      # @return [String] absolute path to app bundle (.app) or `nil` if the
      #  app bundle cannot be found.
      # @todo methods should not use 2 optional arguments
      def detect_app_bundle(path=nil,device_build_dir='iPhoneSimulator')
        begin
          app_bundle_or_raise(path,device_build_dir)
        rescue
          nil
        end
      end

      # @!visibility private
      # Attempts to deduce the path the to the app bundle (.app).
      # @param [String] path NEEDS DOCUMENTATION
      # @param [String] device_build_dir NEEDS DOCUMENTATION
      # @return [String] absolute path to app bundle (.app)
      # @raise [RuntimeError] if app bundle (.app) cannot be found
      # @todo methods should not use 2 optional arguments
      def app_bundle_or_raise(path=nil, device_build_dir='iPhoneSimulator')
        path = File.expand_path(path) if path

        if path and not File.directory?(path)
          raise "Unable to find .app bundle at #{path}. It should be an .app directory."
        elsif path
          bundle_path = path
        elsif xamarin_project?
          bundle_path = bundle_path_from_xamarin_project(device_build_dir)
          unless bundle_path
            msg = ['Detected Xamarin project, but did not detect built app linked with Calabash']
            msg << 'You should build your project from Xamarin Studio'
            msg << "Make sure you build for Simulator and that you're using the Calabash components"
            raise msg.join("\n")
          end
          if full_console_logging?
            puts('-'*37)
            puts "Auto detected APP_BUNDLE_PATH:\n\n"

            puts "APP_BUNDLE_PATH= '#{bundle_path}'\n\n"
            puts 'Please verify!'
            puts "If this is wrong please set it as APP_BUNDLE_PATH in features/support/01_launch.rb\n"
            puts('-'*37)
          end
        else
          bo_dir = build_output_dir_for_project
          sim_dirs = Dir.glob(File.join(bo_dir, '*-iphonesimulator', '*.app'))
          
          if sim_dirs.empty?
            msg = ['Unable to auto detect APP_BUNDLE_PATH.']
            msg << 'Have you built your app for simulator?'
            msg << "Searched dir: #{bo_dir}"
            msg << 'Please build your app from Xcode'
            msg << 'You should build the -cal target.'
            msg << ''
            msg << 'Alternatively, specify APP_BUNDLE_PATH in features/support/01_launch.rb'
            msg << "This should point to the location of your built app linked with calabash.\n"
            raise msg.join("\n")
          end
          preferred_dir = find_preferred_dir(sim_dirs)
          if preferred_dir.nil?
            msg = ['Error... Unable to find APP_BUNDLE_PATH.']
            msg << 'Cannot find a built app that is linked with calabash.framework'
            msg << 'Please build your app from Xcode'
            msg << 'You should build your calabash target.'
            msg << ''
            msg << 'Alternatively, specify APP_BUNDLE_PATH in features/support/01_launch.rb'
            msg << "This should point to the location of your built app linked with calabash.\n"
            raise msg.join("\n")
          end
          if full_console_logging?
            puts('-'*37)
            puts "Auto detected APP_BUNDLE_PATH:\n\n"

            puts "APP_BUNDLE_PATH=#{preferred_dir || sim_dirs[0]}\n\n"
            puts 'Please verify!'
            puts "If this is wrong please set it as APP_BUNDLE_PATH in features/support/01_launch.rb\n"
            puts('-'*37)
          end
          bundle_path = sim_dirs[0]
        end
        bundle_path
      end

      # @!visibility private
      # Is this a Xamarin IDE project?
      # @return [Boolean] true if the project is a Xamarin IDE project
      def xamarin_project?
        xamarin_ios_csproj_path != nil
      end

      # @!visibility private
      # Path to the Xamarin IDE project.
      # @return [String] absolute path to the Xamarin IDE project
      def xamarin_ios_csproj_path
        solution_path = Dir['*.sln'].first

        project_dir = nil
        if solution_path
          project_dir = Dir.pwd
        else
          solution_path = Dir[File.join('..','*.sln')].first
          if solution_path
            project_dir = File.expand_path('..')
          end
        end

        return nil unless project_dir

        ios_project_dir = Dir[File.join(project_dir,'*.iOS')].first
        return ios_project_dir if ios_project_dir && File.directory?(ios_project_dir)
        # ios_project_dir does not exist
        # Detect case where there is no such sub directory
        # (i.e. iOS only Xamarin project)
        bin_dir = File.join(project_dir, 'bin')
        if xamarin_ios_bin_dir?(bin_dir)
            return project_dir ## Looks like iOS bin dir is here
        end

        sub_dirs = Dir[File.join(project_dir,'*')].select {|dir| File.directory?(dir)}

        sub_dirs.find do |sub_dir|
          contains_csproj = Dir[File.join(sub_dir,'*.csproj')].first
          contains_csproj && xamarin_ios_bin_dir?(File.join(sub_dir,'bin'))
        end

      end

      # @!visibility private
      # Is this the Xamarin iOS bin directory?
      # @return [Boolean] true if this is the Xamarin iOS bin directory
      def xamarin_ios_bin_dir?(bin_dir)
        File.directory?(bin_dir) &&
            (File.directory?(File.join(bin_dir,'iPhoneSimulator')) ||
                File.directory?(File.join(bin_dir,'iPhone')))
      end

      # @!visibility private
      # Attempts to deduce the path to the app bundle path (*.app) using
      # heuristics and checking for executables linked with the Calabash server.
      #
      # @param [String] device_build_dir NEEDS DOCUMENTATION
      # @return [String] absolute path the app bundle .app or `nil` if the
      #  the app bundle cannot be found.
      def bundle_path_from_xamarin_project(device_build_dir='iPhoneSimulator')
        ios_project_path = xamarin_ios_csproj_path
        conf_glob = File.join(ios_project_path,'bin',device_build_dir,'*')
        built_confs = Dir[conf_glob]

        calabash_build = built_confs.find {|path| File.basename(path) == 'Calabash'}
        debug_build = built_confs.find {|path| File.basename(path) == 'Debug'}

        bundle_path = [calabash_build, debug_build, *built_confs].find do |path|
          next unless path && File.directory?(path)
          app_dir = Dir[File.join(path,'*.app')].first
          app_dir && linked_with_calabash?(app_dir)
        end

        Dir[File.join(bundle_path,'*.app')].first if bundle_path
      end

      # @!visibility private
      # Searches `d` for a file linked with Calabash server.
      # @param [String] d path to a directory
      # @return [Boolean] true if there is a file that is linked with the
      #   Calabash server
      # @todo why are we not grep'ing for executable files? see server_version_from_bundle
      def linked_with_calabash?(d)
        skipped_formats = ['.png', '.jpg', '.jpeg', '.plist', '.nib', '.lproj']
        dir = File.expand_path(d)

        # For every file on that .app directory
        Dir.entries(d).each do |file|
          # If this is an asset or any of those skipped formats, skip it.
          next if skipped_formats.include? File.extname(file)

          # If its not, try to run otool against that file, check whether we are linked against calabash framework.
          out = `otool "#{dir}/#{file}" -o 2> /dev/null | grep CalabashServer`
          return true if /CalabashServer/.match(out)
        end

        # Defaulted to false
        false
      end

      # !@visibility private
      # Finds the preferred(?) directory.
      # @return [String] The first path in `sim_dirs` that contains a binary
      #   linked with Calabash server. Returns `nil` if there is no path in
      #   `sim_dirs` that contains a binary linked with Calabash server.
      # @param [Array<String>] sim_dirs eke! why sim_dirs?  why not a list of any directories?
      # @todo find_preferred_dir is a bad name - preferred for what?
      # @todo sim_dirs arg is a bad name - we can be iterating over any directory
      def find_preferred_dir(sim_dirs)
        sim_dirs.find do |d|
          linked_with_calabash?(d)
        end
      end

      # !@visibility private
      # Ping the version route of the calabash server embedded in the app,
      #
      # @note
      #   Has the side effect of setting self.device attribute if successful.
      #
      # @return [String] returns the server status - '200' is a success
      # @todo migrate DEVICE_ENDPOINT to environment_helpers
      # @todo migrate CALABASH_VERSION_PATH to environment_helpers
      # @todo this is an exact duplicate of Launcher ping method
      def ping_app
        url = URI.parse(ENV['DEVICE_ENDPOINT']|| 'http://localhost:37265/')
        if full_console_logging?
          puts "Ping #{url}..."
        end

        http = Net::HTTP.new(url.host, url.port)
        res = http.start do |sess|
          # noinspection RubyResolve
          sess.request Net::HTTP::Get.new(ENV['CALABASH_VERSION_PATH'] || 'version')
        end

        status = res.code
        begin
          http.finish if http and http.started?
        rescue
          # nop
        end

        if status == '200'
          version_body = JSON.parse(res.body)
          self.device = Calabash::Cucumber::Device.new(url, version_body)
        end

        if full_console_logging?
          puts "ping status = '#{status}'"
        end
        status
      end

      # @!visibility private
      # Attempts to connect to launch the app and connect to the embedded
      # calabash server.
      #
      # @note To change the number of times launching is attempted set
      # `MAX_CONNECT_RETRY`.
      #
      # @note To change the relaunch timeout set `CONNECT_TIMEOUT`.
      #
      # @param [String] app_bundle_path path to the .app that should be launched
      # @param [String] sdk 6.0.3, 6.1.  if nil latest SDK will be used
      # @param [String] device_family `{iphone | ipad}`
      # @param [Hash] args eke! not used (see todo)
      #
      # @raise [TimeoutErr] if app cannot be launched in the simulator
      # @todo nearly a duplicate of Launcher ensure_connectivity
      # @todo args was originally intended to be the args passed to the application @ launch
      def ensure_connectivity(app_bundle_path, sdk, device_family, args = nil)
        begin
          # todo should get the retry could from the args
          # todo should migrate MAX_CONNECT_RETRY to environment_helpers
          max_retry_count = (ENV['MAX_CONNECT_RETRY'] || DEFAULT_SIM_RETRY).to_i
          # todo should get the timeout from the args
          # todo should migrate CONNECT_TIMEOUT to environment helpers
          timeout = (ENV['CONNECT_TIMEOUT'] || DEFAULT_SIM_WAIT).to_i
          retry_count = 0
          connected = false

          if full_console_logging?
            puts "Waiting at most #{timeout} seconds for simulator (CONNECT_TIMEOUT)"
            puts "Retrying at most #{max_retry_count} times (MAX_CONNECT_RETRY)"
          end

          until connected do
            raise 'MAX_RETRIES' if retry_count == max_retry_count
            retry_count += 1
            if full_console_logging?
              puts "(#{retry_count}.) Start Simulator #{sdk}, #{device_family}, for #{app_bundle_path}"
            end
            begin
              Timeout::timeout(timeout, TimeoutErr) do
                launch(app_bundle_path, sdk, device_family, args)
                until connected
                  begin
                    connected = (ping_app == '200')
                    break if connected
                  ensure
                    sleep 1 unless connected
                  end
                end
              end
            rescue TimeoutErr => e
              puts 'Timed out... Retrying'
              stop
            end
          end
        rescue RuntimeError => e
          p e
          msg = "Unable to make connection to Calabash Server at #{ENV['DEVICE_ENDPOINT']|| 'http://localhost:37265/'}\n"
          msg << "Make sure you've' linked correctly with calabash.framework and set Other Linker Flags.\n"
          msg << "Make sure you don't have a firewall blocking traffic to #{ENV['DEVICE_ENDPOINT']|| 'http://localhost:37265/'}.\n"
          raise msg
        end
      end

      # @!visibility private
      # Launches the app.
      #
      # @param [String] app_bundle_path path to the .app that should be launched
      # @param [String] sdk 6.0.3, 6.1.  if nil latest SDK will be used
      # @param [String] device_family `{iphone | ipad}`
      # @param [Hash] args eke! not used
      # @todo args was originally intended to be the args passed to the application @ launch
      def launch(app_bundle_path, sdk, device_family, args = nil)
        # cached but not used
        self.launch_args = args
        # launch arguments (eg. -NSShowNonLocalizedStrings) are not being passed
        # to sim_launcher
        # https://github.com/calabash/calabash-ios/issues/363
        self.simulator.launch_ios_app(app_bundle_path, sdk, device_family)
        simulator
      end

      # @!visibility private
      # Relaunches the app in the simulator.
      #
      # @param [String] app_path the path to the .app
      # @param [String] sdk eg. 6.0.3, 6.1
      # @param [Hash] args the only option we are interested in is :device
      #
      # @todo args was originally intended to be the args passed to the application @ launch
      # @todo it is _very_ likely that args[:app] == app_path so we might be able
      #   to eliminate an argument
      def relaunch(app_path, sdk, args)
        app_bundle_path = app_bundle_or_raise(app_path)

        if sdk.nil?
          # iOS 7 requires launching with instruments, so we _must_ launch with
          # the first SDK that is _not_ iOS 7
          _sdk = self.sdk_detector.available_sdk_versions.reverse.find { |x| !x.start_with?('7') }
        else
          # use SDK_VERSION to specify a different version
          # as of Xcode 5.0.2, the min supported simulator version is iOS 6
          _sdk = sdk
        end

        if args[:device]
          device_family = args[:device].to_s
        else
          device_family = 'iphone'
        end

        self.launch_args = args

        ensure_connectivity(app_bundle_path, _sdk, device_family, args)
      end

      # @deprecated 0.9.169 Calabash::Cucumber::Launcher.launcher.device instance methods
      # @raise [NotImplementedError] no longer implemented
      def get_version
        _deprecated('0.9.169', 'use an instance Device class instead', :warn)
        raise(NotImplementedError, 'this method has been deprecated')
      end

      # @deprecated 0.9.169 Calabash::Cucumber::Launcher.launcher.device instance methods
      # @raise [NotImplementedError] no longer implemented
      def ios_version
        _deprecated('0.9.169', 'use an instance Device class instead', :warn)
        raise(NotImplementedError, 'this method has been deprecated')
      end

      # @deprecated 0.9.169 use Calabash::Cucumber::Launcher.launcher.ios_major_version
      # @raise [NotImplementedError] no longer implemented
      def ios_major_version
        _deprecated('0.9.169', 'use an instance Device class instead', :warn)
        raise(NotImplementedError, 'this method has been deprecated')
      end


      # noinspection RubyUnusedLocalVariable

      # @deprecated 0.9.169 version checking is done in Launcher
      # @raise [NotImplementedError] no longer implemented
      def version_check(version)
        _deprecated('0.9.169', 'check is now done in Launcher', :warn)
        raise(NotImplementedError, 'this method has been deprecated and will be removed')
      end
    end

  end
end
