
module Calabash
  module Cucumber
    # @!visibility private
    class UsageTracker
      require "calabash-cucumber/store/preferences"
      require "calabash-cucumber/logging"

      require "httpclient"
      require "run_loop"

      # @!visibility private
      @@track_usage = true

      # @!visibility private
      def self.enable_usage_tracking
        @@track_usage = true
      end

      # @!visibility private
      def self.disable_usage_tracking
        @@track_usage = false
      end

      # @!visibility private
      def post_usage
        if Calabash::Cucumber::UsageTracker.track_usage? &&
            info_we_are_allowed_to_track != "none"
          begin
            HTTPClient.post(ROUTE, info)
          rescue => e
            message = %Q{ERROR: Could not post usage tracking information:#{$-0}#{e}}
            Calabash::Cucumber::log_to_file(message)
          end
        end
      end

      # @!visibility private
      def post_usage_async
        t = Thread.new do
          post_usage
        end

        m = Thread.current

        Thread.new do
          loop do
            unless t.alive?
              break
            end

            unless m.alive?
              t.kill
              break
            end
          end
        end
        nil
      end

      private

      # @!visibility private
      def preferences
        Calabash::Cucumber::Preferences.new
      end

      # @!visibility private
      def user_id
        preferences.user_id
      end

      # @!visibility private
      def info_we_are_allowed_to_track
        preferences.usage_tracking
      end

      # @!visibility private
      def self.track_usage?
        @@track_usage && !self.xtc?
      end

      # @!visibility private
      def self.xtc?
        ENV["XAMARIN_TEST_CLOUD"] == "1"
      end

      # @!visibility private
      DATA_VERSION = "1.1"

      # @!visibility private
      WINDOWS = "Windows"

      # @!visibility private
      OSX = "Darwin"

      # @!visibility private
      CALABASH_IOS = "iOS"

      # @!visibility private
      CALABASH_ANDROID = "Android"

      # @!visibility private
      ROUTE = "http://calabash-ci.macminicolo.net:56789/logEvent"

      # @!visibility private
      def host_os
        @host_os ||= lambda do
          if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
            WINDOWS
          else
            `uname -s`.chomp
          end
        end.call
      end

      # @!visibility private
      def host_os_version
        @host_os_version ||= lambda do
          if host_os == WINDOWS
            `ver`.chomp
          elsif host_os == OSX
            `sw_vers -productVersion`.chomp
          else
            `uname -r`.chomp
          end
        end.call
      end

      # @!visibility private
      def irb?
        $0 == "irb"
      end

      # @!visibility private
      def ruby_version
        @ruby_version ||= `#{RbConfig.ruby} -v`.chomp
      end

      # @!visibility private
      def used_bundle_exec?
        Object.const_defined?(:Bundler)
      end

      # @!visibility private
      def used_cucumber?
        Object.const_defined?(:Cucumber)
      end

      # @!visibility private
      #
      # Collect a hash of usage info.
      def info

        allowed = info_we_are_allowed_to_track

        if allowed == "none"
          raise RuntimeError,
            "This method should not be called if the user does not want to be tracked."
        end

        # Events only
        hash = {
          :event_name => "session",
          :data_version => DATA_VERSION,
          :user_id => user_id
        }

        if allowed == "system_info"
          hash.merge!(
            {
              :platform => CALABASH_IOS,
              :host_os => host_os,
              :host_os_version => host_os_version,
              :irb => irb?,
              :ruby_version => ruby_version,
              :used_bundle_exec => used_bundle_exec?,
              :used_cucumber => used_cucumber?,

              :version => Calabash::Cucumber::VERSION,

              :ci => RunLoop::Environment.ci?,
              :jenkins => RunLoop::Environment.jenkins?,
              :travis => RunLoop::Environment.travis?,
              :circle_ci => RunLoop::Environment.circle_ci?,
              :teamcity => RunLoop::Environment.teamcity?,
              :gitlab => RunLoop::Environment.gitlab?
            }
          )
        end

        hash
      end
    end
  end
end

