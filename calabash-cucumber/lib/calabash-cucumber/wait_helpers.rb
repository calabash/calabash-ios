require 'calabash-cucumber/core'
require 'calabash-cucumber/tests_helpers'

module Calabash
  module Cucumber
    module WaitHelpers
      include Calabash::Cucumber::Core
      include Calabash::Cucumber::TestsHelpers

      CALABASH_CONDITIONS = {:none_animating => "NONE_ANIMATING"}


      def wait_for(options_or_timeout=
          {:timeout => 10,
           :retry_frequency => 0.2,
           :post_timeout => 0.1,
           :error_message => nil,
           :screenshot_on_error => true}, &block)
        #note Hash is preferred, number acceptable for backwards compat
        timeout=options_or_timeout
        post_timeout=0.1
        retry_frequency=0.2
        error_message = nil
        screenshot_on_error = true

        if options_or_timeout.is_a?(Hash)
          timeout = options_or_timeout[:timeout] || 10
          retry_frequency = options_or_timeout[:retry_frequency] || 0.2
          post_timeout = options_or_timeout[:post_timeout] || 0.1
          error_message = options_or_timeout[:error_message]
          screenshot_on_error = options_or_timeout[:screenshot_on_error] || true
        end

        begin
          Timeout::timeout(timeout) do
            until block.call
              sleep(retry_frequency)
            end
          end
          sleep(post_timeout) if post_timeout > 0
        rescue Exception => e
          handle_error_with_options(e, error_message, screenshot_on_error)
        end
      end

      #options for wait_for apply
      def wait_for_elements_exist(elements_arr, options={})
        wait_for(options) do
          elements_arr.all? { |q| element_exists(q) }
        end
      end

      def wait_for_condition(options = {})
        options[:timeout] = options[:timeout] || 10
        options[:query] = options[:query] || "view"
        options[:condition] = options[:condition] || CALABASH_CONDITIONS[:none_animating]
        options[:post_timeout] = options[:post_timeout] || 0.1
        options[:frequency] = options[:frequency] || 0.2
        options[:retry_frequency] = options[:retry_frequency] || 0.2
        options[:count] = options[:count] || 2
        options[:screenshot_on_error] = options[:screenshot_on_error] || true

        begin
          Timeout::timeout(options[:timeout]) do
            loop do
              res = http({:method => :post, :path => 'condition'},
                         options)
              res = JSON.parse(res)
              break if res['outcome'] == 'SUCCESS'
              sleep(options[:retry_frequency]) if options[:retry_frequency] > 0
            end
            sleep(options[:post_timeout]) if options[:post_timeout] > 0
          end
        rescue Exception => e
          handle_error_with_options(e,options[:error_message], options[:screenshot_on_error])
        end
      end

      def wait_for_none_animating(options = {})
        options[:condition] = CALABASH_CONDITIONS[:none_animating]
        wait_for_condition(options)
      end

      #may be called with a string (query) or an array of strings
      def wait_for_transition(done_queries, check_options={},animation_options={})
        done_queries = [*done_queries]
        wait_for_elements_exist(done_queries,check_options)
        wait_for_none_animating(animation_options)
      end

      def touch_transition(touch_q, done_queries,check_options={},animation_options={})
        touch(touch_q)
        wait_for_transition(done_queries,check_options,animation_options)
      end

      def handle_error_with_options(ex, error_message, screenshot_on_error)
        msg = (error_message || ex)
        if screenshot_on_error
          screenshot_and_raise msg
        else
          raise msg
        end
      end


    end
  end
end
