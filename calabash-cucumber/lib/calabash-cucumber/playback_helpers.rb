require 'calabash-cucumber/utils/logging'
require 'calabash-cucumber/device'

module Calabash
  module Cucumber
    module PlaybackHelpers

      include Calabash::Cucumber::Logging

      DATA_PATH = File.expand_path(File.dirname(__FILE__))

      def recording_name_for(recording_name, os, device)
        #noinspection RubyControlFlowConversionInspection
        if !recording_name.end_with? '.base64'
          "#{recording_name}_#{os}_#{device}.base64"
        else
          recording_name
        end
      end

      def load_recording(recording, rec_dir)
        directories = playback_file_directories(rec_dir)
        directories.each { |dir|
          path = "#{dir}/#{recording}"
          if File.exists?(path)
            return File.read(path)
          end
        }
        nil
      end

      def playback_file_directories (rec_dir)
        # rec_dir is either ENV['PLAYBACK_DIR'] or ./features/playback
        [File.expand_path(rec_dir),
         "#{Dir.pwd}",
         "#{Dir.pwd}/features",
         "#{Dir.pwd}/features/playback",
         "#{DATA_PATH}/resources/"].uniq
      end

      def load_playback_data(recording_name, options={})
        device = options['DEVICE'] || ENV['DEVICE'] || 'iphone'

        major = Calabash::Cucumber::Launcher.launcher.ios_major_version

        unless major
          raise <<EOF
          Unable to determine iOS major version
          Most likely you have updated your calabash-cucumber client
          but not your server. Please follow closely:

https://github.com/calabash/calabash-ios/wiki/B1-Updating-your-Calabash-iOS-version

          If you are running version 0.9.120+ then please report this message as a bug.
EOF
        end
        os = "ios#{major}"

        rec_dir = ENV['PLAYBACK_DIR'] || "#{Dir.pwd}/features/playback"

        candidates = []
        data = find_compatible_recording(recording_name, os, rec_dir, device, candidates)

        if data.nil? and device=='ipad'
          if full_console_logging?
            puts "Unable to find recording for #{os} and #{device}. Trying with #{os} iphone"
          end
          data = find_compatible_recording(recording_name, os, rec_dir, 'iphone', candidates)
        end

        if data.nil?
          searched_for = "  searched for => \n"
          candidates.each { |file| searched_for.concat("    * '#{file}'\n") }
          searched_in = "  in directories =>\n"
          playback_file_directories(rec_dir).each { |dir| searched_in.concat("    * '#{dir}'\n") }
          raise "Playback file not found for: '#{recording_name}'\n#{searched_for}#{searched_in}"
        end

        data
      end

      def find_compatible_recording (recording_name, os, rec_dir, device, candidates)
        recording = recording_name_for(recording_name, os, device)
        data = load_recording(recording, rec_dir)
        if data.nil?
          candidates << recording
          version_counter = os[-1, 1].to_i
          loop do
            version_counter = version_counter - 1
            break if version_counter < 5
            loop_os = "ios#{version_counter}"
            recording = recording_name_for(recording_name, loop_os, device)
            candidates << recording
            data = load_recording(recording, rec_dir)
            #noinspection RubyControlFlowConversionInspection
            break if !data.nil?
          end
        end
        data
      end

      def playback(recording, options={})
        data = load_playback_data(recording)

        post_data = %Q|{"events":"#{data}"|
        post_data<< %Q|,"query":"#{escape_quotes(options[:query])}"| if options[:query]
        post_data<< %Q|,"offset":#{options[:offset].to_json}| if options[:offset]
        post_data<< %Q|,"reverse":#{options[:reverse]}| if options[:reverse]
        post_data<< %Q|,"uia_gesture":"#{options[:uia_gesture]}"| if options[:uia_gesture]
        post_data<< %Q|,"prototype":"#{options[:prototype]}"| if options[:prototype]
        post_data << '}'

        res = http({:method => :post, :raw => true, :path => 'play'}, post_data)

        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          raise "playback failed because: #{res['reason']}\n#{res['details']}"
        end
        res['results']
      end

      def interpolate(recording, options={})
        data = load_playback_data(recording)

        post_data = %Q|{"events":"#{data}"|
        post_data<< %Q|,"start":"#{escape_quotes(options[:start])}"| if options[:start]
        post_data<< %Q|,"end":"#{escape_quotes(options[:end])}"| if options[:end]
        post_data<< %Q|,"offset_start":#{options[:offset_start].to_json}| if options[:offset_start]
        post_data<< %Q|,"offset_end":#{options[:offset_end].to_json}| if options[:offset_end]
        post_data << '}'

        res = http({:method => :post, :raw => true, :path => 'interpolate'}, post_data)

        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          raise "interpolate failed because: #{res['reason']}\n#{res['details']}"
        end
        res['results']
      end

      def record_begin
        http({:method => :post, :path => 'record'}, {:action => :start})
      end

      def record_end(file_name)
        res = http({:method => :post, :path => 'record'}, {:action => :stop})
        File.open('_recording.plist', 'wb') do |f|
          f.write res
        end

        device = ENV['DEVICE'] || 'iphone'

        major = Calabash::Cucumber::Launcher.launcher.ios_major_version

        unless major
          raise <<EOF
          Unable to determine iOS major version
          Most likely you have updated your calabash-cucumber client
          but not your server. Please follow closely:

https://github.com/calabash/calabash-ios/wiki/B1-Updating-your-Calabash-iOS-version

          If you are running version 0.9.120+ then please report this message as a bug.
EOF

        end
        os = "ios#{major}"

        file_name = "#{file_name}_#{os}_#{device}.base64"
        system('/usr/bin/plutil -convert binary1 -o _recording_binary.plist _recording.plist')
        system("openssl base64 -in _recording_binary.plist -out '#{file_name}'")
        system('rm _recording.plist _recording_binary.plist')

        rec_dir = ENV['PLAYBACK_DIR'] || "#{Dir.pwd}/features/playback"
        unless File.directory?(rec_dir)
          if full_console_logging?
            puts "creating playback directory at '#{rec_dir}'"
          end
          system("mkdir -p #{rec_dir}")
        end

        system("mv #{file_name} #{rec_dir}")
        "#{file_name} ==> '#{rec_dir}/#{file_name}'"

      end

    end
  end
end