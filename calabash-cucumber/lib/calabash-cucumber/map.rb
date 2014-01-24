require 'json'

module Calabash
  module Cucumber
    module Map #=> Connection

      def map(query, method_name, *method_args)
        raw_map(query,method_name, *method_args)['results']
      end

      def raw_map(query, method_name, *method_args)
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

        res
      end

      def expect_map_results(views_touched, msg)
        compact = views_touched.compact
        if compact.empty? or compact.member? '<VOID>'
          screenshot_and_raise msg
        end
      end
    end
  end
end