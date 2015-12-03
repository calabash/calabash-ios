require 'httpclient'

module Calabash
  module Cucumber

    # @!visibility private
    module HTTPHelpers

      # @!visibility private
      CAL_HTTP_RETRY_COUNT=3

      # @!visibility private
      RETRYABLE_ERRORS = [HTTPClient::TimeoutError,
                          HTTPClient::KeepAliveDisconnected,
                          Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ECONNABORTED,
                          Errno::ETIMEDOUT]

      # @!visibility private
      def http(options, data=nil)
        options[:uri] = url_for(options[:path])
        options[:method] = options[:method] || :get
        if data
          if options[:raw]
            options[:body] = data
          else
            options[:body] = data.to_json
          end
        end
        res = make_http_request(options)
        res.force_encoding("UTF-8") if res.respond_to?(:force_encoding)
        res
      end

      # @!visibility private
      def url_for(verb)
        url = URI.parse(ENV['DEVICE_ENDPOINT']|| "http://localhost:37265")
        path = url.path
        if path.end_with? "/"
          path = "#{path}#{verb}"
        else
          path = "#{path}/#{verb}"
        end
        url.path = path
        url
      end

      # @!visibility private
      def make_http_request(options)
        retryable_errors = options[:retryable_errors] || RETRYABLE_ERRORS
        CAL_HTTP_RETRY_COUNT.times do |count|
          begin
            if not @http
              @http = init_request(options)
            end

            response = if options[:method] == :post
              @http.post(options[:uri], options[:body])
            else
              @http.get(options[:uri], options[:body])
            end

            raise Errno::ECONNREFUSED if response.status_code == 502

            return response.body
          rescue => e

            if retryable_errors.include?(e) || retryable_errors.any? { |c| e.is_a?(c) }

              if count < CAL_HTTP_RETRY_COUNT-1
                if e.is_a?(HTTPClient::TimeoutError)
                  sleep(3)
                else
                  sleep(0.5)
                end
                @http.reset_all
                @http=nil
                STDOUT.write "Retrying.. #{e.class}: (#{e})\n"
                STDOUT.flush
              else
                puts "Failing... #{e.class}"
                raise e
              end
            else
              raise e
            end
          end
        end
      end

      # @!visibility private
      def init_request(options={})
        http = HTTPClient.new
        http.connect_timeout = 30
        http.send_timeout = 120
        http.receive_timeout = 120
        if options[:debug] || (ENV['DEBUG_HTTP'] == '1' && options[:debug] != false)
          http.debug_dev = $stdout
        end
        http
      end

    end
  end
end
