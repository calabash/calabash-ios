module Calabash
  module Cucumber

    # Raised when a connection to the embedded server cannot be made.
    class ServerNotRespondingError < RuntimeError; end

    # @!visibility private
    class HTTP

      require "calabash-cucumber/environment"
      require "run_loop"

      # @!visibility private
      def self.ping_app
        endpoint = Calabash::Cucumber::Environment.device_endpoint
        url = URI.parse(endpoint)

        http = Net::HTTP.new(url.host, url.port)
        response = http.start do |sess|
          sess.request(Net::HTTP::Get.new("version"))
        end

        body = nil
        success = response.is_a?(Net::HTTPSuccess)
        if success
          body = response.body
        end

        http.finish if http and http.started?

        return success, body
      end

      # @!visibility private
      def self.ensure_connectivity(options={})

        default_options = {
          :http_connection_retry => Calabash::Cucumber::Environment.http_connection_retries,
          :http_connection_timeout => Calabash::Cucumber::Environment.http_connection_timeout
        }

        merged_options = default_options.merge(options)

        max_retry_count = merged_options[:http_connection_retry]
        timeout = merged_options[:http_connection_timeout]

        start_time = Time.now

        max_retry_count.times do |try|
          RunLoop.log_debug("Trying to connect to Calabash Server: #{try + 1} of #{max_retry_count}")

          # Subtract the aggregate time we've spent thus far to make sure we're
          # not exceeding the request timeout across retries.
          time_diff = start_time + timeout - Time.now

          if time_diff <= 0
            break
          end

          begin
            success, body = self.ping_app
            return success, body if success
          rescue => _

          ensure
            sleep(1)
          end
        end

        endpoint = Calabash::Cucumber::Environment.device_endpoint

        raise Calabash::Cucumber::ServerNotRespondingError,
              %Q[Could not connect to the Calabash Server @ #{endpoint}.

See these two guides for help.

* https://github.com/calabash/calabash-ios/wiki/Testing-on-Physical-Devices
* https://github.com/calabash/calabash-ios/wiki/Testing-on-iOS-Simulators

1. Make sure your application is linked with Calabash.
2. Make sure there is not a firewall blocking traffic on #{endpoint}.
3. Make sure #{endpoint} is correct.

If your app is crashing at launch, find a crash report to determine the cause.

]
      end
    end
  end
end

