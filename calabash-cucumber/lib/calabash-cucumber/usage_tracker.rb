module Calabash
  module Cucumber
    class UsageTracker

      require "httpclient"
      require "run_loop"

      # @!visibility private
      @@post_usage = true

      # @!visibility private
      def self.enable_usage_posting
        @@post_usage = true
      end

      # @!visibility private
      def self.disable_usage_posting
        @@post_usage = false
      end

      # @!visibility private
      def post_usage
        if ENV["XAMARIN_TEST_CLOUD"] != "1" && @@post_usage
          begin
            HTTPClient.post(ROUTE, info)
          rescue => _
            # do nothing
            # Perhaps we should log?
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
      DATA_VERSION = "1.0"

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
      def os
        @os ||= lambda do
          if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
            WINDOWS
          else
            `uname -s`.chomp
          end
        end.call
      end

      # @!visibility private
      def os_version
        @os_version ||= lambda do
          if os == WINDOWS
            `ver`.chomp
          elsif os == OSX
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
      # The behavior here is TBD.
      #
      # False is the obvious default; this should be an opt in behavior.
      def include_ip?
        false
      end

      # @!visibility private
      #
      # Collect a hash of usage info.
      def info
        {
          :event_name => "session",
          :data_version => DATA_VERSION,
          :include_ip? => include_ip?,

          :platform => CALABASH_IOS,
          :os => os,
          :os_version => os_version,
          :irb => irb?,
          :ruby_version => ruby_version,
          :used_bundle_exec => used_bundle_exec?,
          :used_cucumber => used_cucumber?,

          :version => Calabash::Cucumber::VERSION,

          :ci => RunLoop::Environment.ci?,
          :jenkins => RunLoop::Environment.jenkins?,
          :travis => RunLoop::Environment.travis?,
          :circle_ci => RunLoop::Environment.circle_ci?,
          :teamcity => RunLoop::Environment.teamcity?
        }
      end
    end
  end
end

