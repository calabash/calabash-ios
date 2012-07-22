require 'calabash-cucumber/tests_helpers'

module Calabash
  module Cucumber
    module WaitHelpers
      include Calabash::Cucumber::TestsHelpers

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
