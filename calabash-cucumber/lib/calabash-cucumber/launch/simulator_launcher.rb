require 'sim_launcher'
require 'json'
require 'net/http'
require 'cfpropertylist'
require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber

    class SimulatorLauncher
      include Calabash::Cucumber::Logging

      class TimeoutErr < RuntimeError
      end

      DERIVED_DATA = File.expand_path('~/Library/Developer/Xcode/DerivedData')
      DEFAULT_DERIVED_DATA_INFO = File.expand_path("#{DERIVED_DATA}/*/info.plist")

      DEFAULT_SIM_WAIT = 30
      DEFAULT_SIM_RETRY = 2

      # Calabash::Cucumber::Device
      attr_accessor :device
      # SimLauncher::Simulator
      attr_accessor :simulator
      # SimLauncher::SdkDetector
      attr_accessor :sdk_detector

      # launch args passed in from Launcher
      attr_accessor :launch_args

      def initialize
        @simulator = SimLauncher::Simulator.new
        @sdk_detector = SimLauncher::SdkDetector.new()
      end

      def relaunch(path, sdk = nil, version = 'iphone', args = nil)
        # cached, but not used
        self.launch_args = args
        app_bundle_path = app_bundle_or_raise(path)
        ensure_connectivity(app_bundle_path, sdk, version, args)
      end

      def stop
        self.simulator.quit_simulator
      end

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

        # todo analyze `self.derived_data_dir_for_project` to see if it contains dead code
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

      def project_dir
        File.expand_path(ENV['PROJECT_DIR'] || Dir.pwd)
      end

      def detect_app_bundle(path=nil,device_build_dir='iPhoneSimulator')
        begin
          app_bundle_or_raise(path,device_build_dir)
        rescue
          nil
        end
      end

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
          dd_dir = derived_data_dir_for_project
          sim_dirs = Dir.glob(File.join(dd_dir, 'Build', 'Products', '*-iphonesimulator', '*.app'))
          if sim_dirs.empty?
            msg = ['Unable to auto detect APP_BUNDLE_PATH.']
            msg << 'Have you built your app for simulator?'
            msg << "Searched dir: #{dd_dir}/Build/Products"
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

      def xamarin_project?
        xamarin_ios_csproj_path != nil
      end

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

      def xamarin_ios_bin_dir?(bin_dir)
        File.directory?(bin_dir) &&
            (File.directory?(File.join(bin_dir,'iPhoneSimulator')) ||
                File.directory?(File.join(bin_dir,'iPhone')))
      end

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

      def linked_with_calabash?(d)
        skipped_formats = ['.png', '.jpg', '.jpeg', '.plist', '.nib', '.lproj']
        dir = File.expand_path(d)

        # For every file on that .app directory
        Dir.entries(d).each do |file|
          # If this is an asset or any of those skipped formats, skip it.
          next if skipped_formats.include? File.extname(file)

          # If its not, try to run otool against that file, check whether we are linked against calabash framework.
          out = `otool #{dir}/#{file} -o 2> /dev/null | grep CalabashServer`
          return true if /CalabashServer/.match(out)
        end

        # Defaulted to false
        false
      end

      def find_preferred_dir(sim_dirs)
        sim_dirs.find do |d|
          linked_with_calabash?(d)
        end
      end

      def ensure_connectivity(app_bundle_path, sdk, version, args = nil)
        begin
          # todo should get the retry could from the args
          max_retry_count = (ENV['MAX_CONNECT_RETRY'] || DEFAULT_SIM_RETRY).to_i
          # todo should get the timeout from the args
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
              puts "(#{retry_count}.) Start Simulator #{sdk}, #{version}, for #{app_bundle_path}"
            end
            begin
              Timeout::timeout(timeout, TimeoutErr) do
                launch(app_bundle_path, sdk, version, args)
                until connected
                  begin
                    connected = (ping_app == '200')
                    break if connected
                  rescue Exception => e
                    # nop
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


      def launch(app_bundle_path, sdk, version, args = nil)
        # cached but not used
        self.launch_args = args
        self.simulator.launch_ios_app(app_bundle_path, sdk, version)
        simulator
      end

      # duplicate of Launcher ping method
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
          puts "ping status = '#{status}"
        end
        status
      end

      def get_version
        _deprecated('0.9.169', 'use an instance Device class instead', :warn)
        raise(NotImplementedError, 'this method has been deprecated')
      end

      def ios_version
        _deprecated('0.9.169', 'use an instance Device class instead', :warn)
        raise(NotImplementedError, 'this method has been deprecated')
      end

      def ios_major_version
        _deprecated('0.9.169', 'use an instance Device class instead', :warn)
        raise(NotImplementedError, 'this method has been deprecated')
      end

      # noinspection RubyUnusedLocalVariable
      def version_check(version)
        _deprecated('0.9.169', 'check is now done in Launcher', :warn)
        raise(NotImplementedError, 'this method has been deprecated and will be removed')
      end
    end

  end
end
