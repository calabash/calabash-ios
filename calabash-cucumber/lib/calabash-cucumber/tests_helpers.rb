module Calabash
  module Cucumber
    module TestsHelpers

      def screenshot_and_raise(msg, prefix=nil, name=nil)
        screenshot(prefix, name)
        raise(msg)
      end

      def fail(msg="Error. Check log for details.", prefix=nil, name=nil)
        screenshot_and_raise(msg, prefix, name)
      end

      def screenshot(prefix=nil, name=nil)
        res = http({:method => :get, :path => 'screenshot'})
        prefix = prefix || ENV['SCREENSHOT_PATH'] || ""
        name = "screenshot_#{CALABASH_COUNT[:step_line]}.png" if name.nil?
        path = "#{prefix}#{name}"
        File.open(path, 'wb') do |f|
          f.write res
        end
        puts "Saved screenshot: #{path}"
        path
      end

      def map(query, method_name, *method_args)
        operation_map = {
            :method_name => method_name,
            :arguments => method_args
        }
        res = http({:method => :post, :path => 'map'},
                   {:query => query, :operation => operation_map})
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "map #{query}, #{method_name} failed because: #{res['reason']}\n#{res['details']}"
        end

        res['results']
      end

      def http(options, data=nil)
        url = url_for(options[:path])
        if options[:method] == :post
          req = Net::HTTP::Post.new url.path
          if options[:raw]
            req.body=data
          else
            req.body = data.to_json
          end

        else
          req = Net::HTTP::Get.new url.path
        end
        make_http_request(url, req)
      end


      def url_for(verb)
        url = URI.parse(ENV['DEVICE_ENDPOINT']|| "http://localhost:37265/")
        url.path = '/'+verb
        url
      end

      CAL_HTTP_RETRY_COUNT=3

      def make_http_request(url, req)
        body = nil
        CAL_HTTP_RETRY_COUNT.times do |count|
          begin
            if not (@http) or not (@http.started?)
              @http = init_request(url)
              @http.start
            end
            body = @http.request(req).body
            break
          rescue Exception => e
            if count < CAL_HTTP_RETRY_COUNT-1
              puts "Retrying.."
            else
              puts "Failing..."
              raise e
            end
          end
        end

        body
      end

      def init_request(url)
        http = Net::HTTP.new(url.host, url.port)
        if http.respond_to? :open_timeout=
          http.open_timeout==15
        end
        http
      end


    end
  end
end
