require 'calabash-cucumber/core'
require 'calabash-cucumber/tests_helpers'

module Calabash
  module Cucumber
    module WaitHelpers
      include Calabash::Cucumber::Core
      include Calabash::Cucumber::TestsHelpers


      class WaitError < RuntimeError
      end
      CALABASH_CONDITIONS = {:none_animating => "NONE_ANIMATING",
                             :no_network_indicator => "NO_NETWORK_INDICATOR"}


      def wait_for(options_or_timeout=
          {:timeout => 10,
           :retry_frequency => 0.2,
           :post_timeout => 0.1,
           :timeout_message => "Timed out waiting...",
           :screenshot_on_error => true}, &block)
        #note Hash is preferred, number acceptable for backwards compat
        timeout=options_or_timeout
        post_timeout=0.1
        retry_frequency=0.2
        timeout_message = nil
        screenshot_on_error = true

        if options_or_timeout.is_a?(Hash)
          timeout = options_or_timeout[:timeout] || 10
          retry_frequency = options_or_timeout[:retry_frequency] || 0.2
          post_timeout = options_or_timeout[:post_timeout] || 0.1
          timeout_message = options_or_timeout[:timeout_message]
          if options_or_timeout.key?(:screenshot_on_error)
            screenshot_on_error = options_or_timeout[:screenshot_on_error]
          end
        end

        begin
          Timeout::timeout(timeout,WaitError) do
            sleep(retry_frequency) until yield
          end
          sleep(post_timeout) if post_timeout > 0
        rescue WaitError => e
          handle_error_with_options(e,timeout_message, screenshot_on_error)
        rescue Exception => e
          handle_error_with_options(e, nil, screenshot_on_error)
        end
      end

      def wait_poll(opts, &block)
        test = opts[:until]
        if test.nil?
          cond = opts[:until_exists]
          raise "Must provide :until or :until_exists" unless cond
          test = lambda { element_exists(cond) }
        end
        wait_for(opts) do
          if test.call()
            true
          else
            yield
            false
          end
        end
      end

      #options for wait_for apply
      def wait_for_elements_exist(elements_arr, options={})
        options[:timeout_message] = options[:timeout_message] || "Timeout waiting for elements: #{elements_arr.join(",")}"
        wait_for(options) do
          elements_arr.all? { |q| element_exists(q) }
        end
      end
      #options for wait_for apply
      def wait_for_elements_do_not_exist(elements_arr, options={})
        options[:timeout_message] = options[:timeout_message] || "Timeout waiting for no elements matching: #{elements_arr.join(",")}"
        wait_for(options) do
          elements_arr.none? { |q| element_exists(q) }
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
        options[:timeout_message] = options[:timeout_message] || "Timeout waiting for condition (#{options[:condition]})"
        options[:screenshot_on_error] = options[:screenshot_on_error] || true

        if options[:condition] == CALABASH_CONDITIONS[:none_animating]
          #puts "Waiting for none-animating has been found unreliable."
          #puts "You are advised not to use it until this is resolved."
          #puts "Test will continue..."
        end
        begin
          Timeout::timeout(options[:timeout],WaitError) do
            loop do
              res = http({:method => :post, :path => 'condition'},
                         options)
              res = JSON.parse(res)
              break if res['outcome'] == 'SUCCESS'
              sleep(options[:retry_frequency]) if options[:retry_frequency] > 0
            end
            sleep(options[:post_timeout]) if options[:post_timeout] > 0
          end
        rescue WaitError => e
          handle_error_with_options(e,options[:timeout_message], options[:screenshot_on_error])
        rescue Exception => e
          handle_error_with_options(e,nil, options[:screenshot_on_error])
        end
      end

      def wait_for_none_animating(options = {})
        #sleep(0.3)
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

      def handle_error_with_options(ex, timeout_message, screenshot_on_error)
        msg = (timeout_message || ex)
        if ex
          msg = "#{msg} (#{ex.class})"
        end
        if screenshot_on_error
          screenshot_and_raise msg
        else
          raise msg
        end
      end


    end
  end
end
