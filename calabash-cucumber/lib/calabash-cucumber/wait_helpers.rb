require 'calabash-cucumber/core'
require 'calabash-cucumber/tests_helpers'

module Calabash
  module Cucumber
    module WaitHelpers
      include Calabash::Cucumber::Core
      include Calabash::Cucumber::TestsHelpers

      CALABASH_CONDITIONS =
          {
              :none_animating => "NONE_ANIMATING"
          }

      def wait_for_condition(timeout,
                         options = {:query => "view", :post_timeout => 0.1,
                                    :condition => CALABASH_CONDITIONS[:none_animating],
                                    :count => 5, :frequency => 0.2})
        begin
          Timeout::timeout(timeout) do
            loop do
              res = http({:method => :post, :path => 'condition'},
                         options)
              res = JSON.parse(res)
              break if res['outcome'] == 'SUCCESS'
            end
            sleep(options[:post_timeout]) if options[:post_timeout] > 0
          end
        end
      end

      def wait_for_none_animating(timeout,
                                  options = {:query => "view", :post_timeout => 0.1,
                                             :count => 5, :frequency => 0.2})
        options[:condition] = CALABASH_CONDITIONS[:none_animating]
        wait_for_condition(time,options)
      end

      def wait_for_elements_exist(elements_arr,
                options={:timeout=>10, :post_timeout => 0.3})
        wait_for(options[:timeout]) do
          (elements_arr.map {|q| element_exists(q)}).all?(true)
        end

      end

      def wait_for(timeout, opt_post_timeout=0.3, &block)
        begin
          Timeout::timeout(timeout) do
            until block.call
              sleep 0.3
            end
          end
          sleep(opt_post_timeout)
        rescue Exception => e
          screenshot_and_raise e
        end
      end

      #def wait_for(timeout, opt_post_timeout=0.3, &block)
      #  begin
      #    Timeout::timeout(timeout) do
      #      until block.call
      #        sleep 0.3
      #      end
      #    end
      #    sleep(opt_post_timeout)
      #  rescue Exception => e
      #    screenshot_and_raise e
      #  end
      #end

    end
  end
end
