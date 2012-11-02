require 'sim_launcher'
require 'json'
require 'net/http'
require 'cfpropertylist'

module Calabash
  module Cucumber

    module SimulatorHelper

      class TimeoutErr < RuntimeError
      end

      DERIVED_DATA = File.expand_path("~/Library/Developer/Xcode/DerivedData")
      DEFAULT_DERIVED_DATA_INFO = File.expand_path("#{DERIVED_DATA}/*/info.plist")

      DEFAULT_SIM_WAIT = 30

      DEFAULT_SIM_RETRY = 2

      def self.relaunch(path, sdk = nil, version = 'iphone', args = nil)

        app_bundle_path = app_bundle_or_raise(path)
        ensure_connectivity(app_bundle_path, sdk, version, args)

      end

      def self.stop
        simulator = SimLauncher::Simulator.new
        simulator.quit_simulator
      end


      def self.derived_data_dir_for_project
        dir = project_dir
        xcode_workspace_name = ''
        info_plist = Dir.glob(DEFAULT_DERIVED_DATA_INFO).find { |plist_file|
          begin
            plist = CFPropertyList::List.new(:file => plist_file)
            hash = CFPropertyList.native_types(plist.value)
            ws_dir = File.dirname(hash['WorkspacePath']).downcase
            p_dir = dir.downcase
            if (p_dir.include? ws_dir)
              xcode_workspace_name = ws_dir.split('/').last
            end
            ws_dir == p_dir
          rescue
            false
          end
        }

        if not info_plist.nil?
          return File.dirname(info_plist)
        else
          res = Dir.glob("#{dir}/*.xcodeproj")
          if res.empty?
            raise "Unable to find *.xcodeproj in #{dir}"
          elsif res.count > 1
            raise "Unable to found several *.xcodeproj in #{dir}: #{res}"
          end

          xcode_proj_name = res.first.split(".xcodeproj")[0]

          xcode_proj_name = File.basename(xcode_proj_name)

          build_dirs = Dir.glob("#{DERIVED_DATA}/*").find_all do |xc_proj|
            File.basename(xc_proj).start_with?(xcode_proj_name)
          end

          if (build_dirs.count == 0 && !xcode_workspace_name.empty?)
            # check for directory named "workspace-{deriveddirectoryrandomcharacters}"
            build_dirs = Dir.glob("#{DERIVED_DATA}/*").find_all do |xc_proj|
              File.basename(xc_proj).downcase.start_with?(xcode_workspace_name)
            end
          end

          if (build_dirs.count == 0)
            msg = ["Unable to find your built app."]
            msg << "This means that Calabash can't automatically launch iOS simulator."
            msg << "Searched in Xcode 4.x default: #{DEFAULT_DERIVED_DATA_INFO}"
            msg << ""
            msg << "To fix there are a couple of options:\n"
            msg << "Option 1) Make sure you are running this command from your project directory, "
            msg << "i.e., the directory containing your .xcodeproj file."
            msg << "In Xcode, build your calabash target for simulator."
            msg << "Check that your app can be found in\n #{File.expand_path("~/Library/Developer/Xcode/DerivedData")}"
            msg << "\n\nOption 2). In features/support/launch.rb set APP_BUNDLE_PATH to"
            msg << "the path where Xcode has built your Calabash target."
            msg << "Alternatively you can use the environment variable APP_BUNDLE_PATH.\n"
            raise msg.join("\n")

          elsif (build_dirs.count > 1)
            msg = ["Unable to auto detect APP_BUNDLE_PATH."]
            msg << "You have several projects with the same name: #{xcode_proj_name} in #{DERIVED_DATA}:\n"
            msg << build_dirs.join("\n")

            msg << "\nThis means that Calabash can't automatically launch iOS simulator."
            msg << "Searched in Xcode 4.x default: #{DEFAULT_DERIVED_DATA_INFO}"
            msg << "\nIn features/support/launch.rb set APP_BUNDLE_PATH to"
            msg << "the path where Xcode has built your Calabash target."
            msg << "Alternatively you can use the environment variable APP_BUNDLE_PATH.\n"
            raise msg.join("\n")
          else
            puts "Found potential build dir: #{build_dirs.first}"
            puts "Checking..."
            return build_dirs.first
          end
        end
      end

      def self.project_dir
        File.expand_path(ENV['PROJECT_DIR'] || Dir.pwd)
      end

      def self.app_bundle_or_raise(path)
        bundle_path = nil
        path = File.expand_path(path) if path

        if path and not File.directory?(path)
          puts "Unable to find .app bundle at #{path}. It should be an .app directory."
          dd_dir = derived_data_dir_for_project
          app_bundles = Dir.glob(File.join(dd_dir, "Build", "Products", "*", "*.app"))
          msg = "Try setting APP_BUNDLE_PATH in features/support/launch.rb to one of:\n\n"
          msg << app_bundles.join("\n")
          raise msg
        elsif path
          bundle_path = path
        else
          dd_dir = derived_data_dir_for_project
          sim_dirs = Dir.glob(File.join(dd_dir, "Build", "Products", "*-iphonesimulator", "*.app"))
          if sim_dirs.empty?
            msg = ["Unable to auto detect APP_BUNDLE_PATH."]
            msg << "Have you built your app for simulator?."
            msg << "Searched dir: #{dd_dir}/Build/Products"
            msg << "Please build your app from Xcode"
            msg << "You should build the -cal target."
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
            msg << "You should build your calabash target."
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
        sim_dirs.find do |d|
          out = `otool "#{File.expand_path(d)}"/* -o 2> /dev/null | grep CalabashServer`
          /CalabashServer/.match(out)
        end
      end

      def self.ensure_connectivity(app_bundle_path, sdk, version, args = nil)
        begin
          max_retry_count = (ENV['MAX_CONNECT_RETRY'] || DEFAULT_SIM_RETRY).to_i
          timeout = (ENV['CONNECT_TIMEOUT'] || DEFAULT_SIM_WAIT).to_i
          retry_count = 0
          connected = false
          puts "Waiting at most #{timeout} seconds for simulator (CONNECT_TIMEOUT)"
          puts "Retrying at most #{max_retry_count} times (MAX_CONNECT_RETRY)"
          until connected do
            raise "MAX_RETRIES" if retry_count == max_retry_count
            retry_count += 1
            puts "(#{retry_count}.) Start Simulator #{sdk}, #{version}, for #{app_bundle_path}"
            begin
              Timeout::timeout(timeout, TimeoutErr) do
                simulator = launch(app_bundle_path, sdk, version, args)
                until connected
                  begin
                    connected = (ping_app == '405')
                    if ENV['POST_START_BREAK']
                      puts "Environment var POST_START_BREAK is deprecated and should no longer be necessary."
                      post_connect_sleep = (ENV['POST_START_BREAK'] || "2").to_f
                      sleep(post_connect_sleep) unless post_connect_sleep <= 0
                    end
                    if connected
                      server_version = get_version
                      if server_version
                        unless version_check(server_version)
                          msgs = ["You're running an older version of Calabash server with a newer client",
                                  "Client:#{Calabash::Cucumber::VERSION}",
                                  "Server:#{server_version}",
                                  "Minimum server version #{Calabash::Cucumber::FRAMEWORK_VERSION}",
                                  "Update recommended:",
                                  "https://github.com/calabash/calabash-ios/wiki/B1-Updating-your-Calabash-iOS-version"
                          ]
                          raise msgs.join("\n")
                        end
                      else
                        connected = false
                      end
                    end
                  rescue Exception => e

                  ensure
                    sleep 1 unless connected
                  end
                end
              end
            rescue TimeoutErr => e
              puts "Timed out..."
            end
          end
        rescue
          msg = "Unable to make connection to Calabash Server at #{ENV['DEVICE_ENDPOINT']|| "http://localhost:37265/"}\n"
          msg << "Make sure you've' linked correctly with calabash.framework and set Other Linker Flags.\n"
          msg << "Make sure you don't have a firewall blocking traffic to #{ENV['DEVICE_ENDPOINT']|| "http://localhost:37265/"}.\n"
          raise msg
        end
      end


      def self.launch(app_bundle_path, sdk, version, args = nil)
        simulator = SimLauncher::Simulator.new
        simulator.quit_simulator
        simulator.launch_ios_app(app_bundle_path, sdk, version, args)
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
        rescue

        end
        status
      end

      def self.get_version
        endpoint = ENV['DEVICE_ENDPOINT']|| "http://localhost:37265"
        endpoint += "/" unless endpoint.end_with? "/"
        url = URI.parse("#{endpoint}version")

        puts "Fetch version #{url}..."
        begin
          body = Net::HTTP.get_response(url).body
          return JSON.parse(body)
        rescue
        end
        nil
      end

      def self.version_check(version)
        server_version = version["version"]
        Calabash::Cucumber::FRAMEWORK_VERSION == server_version
      end
    end

  end
end
