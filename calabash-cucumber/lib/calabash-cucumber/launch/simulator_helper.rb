require 'net/http/persistent'
require 'sim_launcher'
require 'CFPropertyList'

module Calabash
  module Cucumber

    module SimulatorHelper

      DEFAULT_DERIVED_DATA = File.expand_path("~/Library/Developer/Xcode/DerivedData/*/info.plist")
      MAX_PING_ATTEMPTS = 5

      def self.relaunch(path, sdk = nil, version = 'iphone')

        app_bundle_path = app_bundle_or_raise(path)
        ensure_connectivity(app_bundle_path, sdk, version)

      end

      def self.stop
        simulator = SimLauncher::Simulator.new
        simulator.quit_simulator
      end


      def self.derived_data_dir_for_project
        dir = project_dir

        info_plist = Dir.glob(DEFAULT_DERIVED_DATA).find { |plist_file|
          plist = CFPropertyList::List.new(:file => plist_file)
          hash = CFPropertyList.native_types(plist.value)
          ws_dir = File.dirname(hash['WorkspacePath']).downcase
          p_dir = dir.downcase
          ws_dir == p_dir
        }
        if not info_plist.nil?
          File.dirname(info_plist)
        else
          msg = ["Unable to find your built app."]
          msg << "This means that Calabash can't automatically launch iOS simulator."
          msg << "Searched in Xcode 4.x default: #{DEFAULT_DERIVED_DATA}"
          msg << ""
          msg << "To fix there are a couple of options:\n"
          msg << "Option 1) Make sure you are running this command from your project directory, "
          msg << "i.e., the directory containing your .xcodeproj file."
          msg << "In Xcode, build your calabash target or scheme for simulator."
          msg << "Check that your app can be found in\n #{File.expand_path("~/Library/Developer/Xcode/DerivedData")}"
          msg << "\n\nOption 2). In features/support/launch.rb set APP_BUNDLE_PATH to"
          msg << "the path where Xcode has built your Calabash target or scheme."
          msg << "Alternatively you can use the environment variable APP_BUNDLE_PATH.\n"
          raise msg.join("\n")
        end
      end

      def self.project_dir
        File.expand_path(ENV['PROJECT_DIR'] || Dir.pwd)
      end

      def self.app_bundle_or_raise(path)
        dd_dir = derived_data_dir_for_project
        app_bundles = Dir.glob(File.join(dd_dir, "Build", "Products", "*", "*.app"))
        bundle_path = nil

        if path and not File.directory?(path)
          puts "Unable to find .app bundle at #{path}"
          if dd_dir.nil?
            raise "Unable to find Project for #{project_dir} in #{%x[ls #{DEFAULT_DERIVED_DATA}]}"
          end
          if app_bundles.empty?
            raise "Can't find build in #{dd_dir}/Build/Products/*/*.app'. Have you built your app for simulator?"
          end
          msg = "Try setting APP_BUNDLE_PATH in features/support/launch.rb to one of:\n\n"
          msg << app_bundles.join("\n")
          raise msg
        elsif path
          bundle_path = path
        else
          sim_dirs = Dir.glob(File.join(dd_dir, "Build", "Products", "*-iphonesimulator", "*.app"))
          if sim_dirs.empty?
            msg = ["Unable to auto detect APP_BUNDLE_PATH."]
            msg << "Have you built your app for simulator?."
            msg << "Searched dir: #{dd_dir}/Build/Products"
            msg << "Please build your app from Xcode"
            msg << "You should build the -cal scheme or your calabash target."
            msg << ""
            msg << "Alternatively, specify APP_BUNDLE_PATH in features/support/launch.rb"
            msg << "This should point to the location of your built app linked with calabash.\n"
            raise msg.join("\n")
          end
          preferred_dir = find_preferred_dir(sim_dirs)
          if preferred_dir.nil?
            msg = ["Error... Unable to find APP_BUNDLE_PATH."]
            msg << "Cannot find a built app that is linked with calabash.framework"
            msg << "Please build your app from Xcode"
            msg << "You should build the -cal scheme or your calabash target."
            msg << ""
            msg << "Alternatively, specify APP_BUNDLE_PATH in features/support/launch.rb"
            msg << "This should point to the location of your built app linked with calabash.\n"
            raise msg.join("\n")
          end
          puts("-"*37)
          puts "Auto detected APP_BUNDLE_PATH:\n\n"

          puts "APP_BUNDLE_PATH=#{preferred_dir || sim_dirs[0]}\n\n"
          puts "Please verify!"
          puts "If this is wrong please set it as APP_BUNDLE_PATH in features/support/launch.rb\n"
          puts("-"*37)
          bundle_path = sim_dirs[0]
        end
        bundle_path
      end

      def self.find_preferred_dir(sim_dirs)

        pref = sim_dirs.find do |d|
          out = `otool "#{File.expand_path(d)}"/* -o 2> /dev/null | grep CalabashServer`
          /CalabashServer/.match(out)
        end

        if pref.nil?
          pref = sim_dirs.find {|d| /Calabash-iphonesimulator/.match(d)}
        end
        pref
      end

      def self.ensure_connectivity(app_bundle_path, sdk, version)
        begin
          Timeout::timeout(15) do
            connected = false
            until connected
              simulator = launch(app_bundle_path, sdk, version)
              num_pings = 0
              until connected or (num_pings == MAX_PING_ATTEMPTS)
                begin
                    connected = (ping_app == '405')
                rescue Exception => e
                  if (num_pings > 2) then p e end
                ensure
                  num_pings += 1
                  unless connected
                    sleep 1
                  end
                end
              end
            end
          end
        rescue
          msg = "Unable to make connection to Calabash Server at #{ENV['DEVICE_ENDPOINT']|| "http://localhost:37265/"}\n"
          msg << "Make sure you've' linked correctly with calabash.framework and set Other Linker Flags.\n"
          msg << "See: http://github.com/calabash/calabash-ios"
          raise msg
        end
      end


      def self.launch(app_bundle_path, sdk, version)
        simulator = SimLauncher::Simulator.new
        simulator.quit_simulator
        simulator.launch_ios_app(app_bundle_path, sdk, version)
        simulator
      end

      def self.ping_app
        url = URI.parse(ENV['DEVICE_ENDPOINT']|| "http://localhost:37265/")
        puts "Ping #{url}..."
        http = Net::HTTP.new(url.host, url.port)
        res = http.start do |sess|
          sess.request Net::HTTP::Get.new url.path
        end
        status = res.code
        begin
          http.finish if http and http.started?
        rescue Exception => e
          puts "Finish #{e}"
        end
        status
      end
    end


  end
end

