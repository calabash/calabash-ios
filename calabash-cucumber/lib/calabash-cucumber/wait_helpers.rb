require 'calabash-cucumber/core'
require 'calabash-cucumber/tests_helpers'
require 'fileutils'

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
          {:timeout => 30,
           :retry_frequency => 0.3,
           :post_timeout => 0,
           :timeout_message => 'Timed out waiting...',
           :screenshot_on_error => true}, &block)
        #note Hash is preferred, number acceptable for backwards compat
        default_timeout = 30
        timeout = options_or_timeout || default_timeout
        post_timeout=0
        retry_frequency=0.3
        timeout_message = nil
        screenshot_on_error = true

        if options_or_timeout.is_a?(Hash)
          timeout = options_or_timeout[:timeout] || default_timeout
          retry_frequency = options_or_timeout[:retry_frequency] || retry_frequency
          post_timeout = options_or_timeout[:post_timeout] || post_timeout
          timeout_message = options_or_timeout[:timeout_message]
          if options_or_timeout.key?(:screenshot_on_error)
            screenshot_on_error = options_or_timeout[:screenshot_on_error]
          end
        end

        begin
          Timeout::timeout(timeout, WaitError) do
            sleep(retry_frequency) until yield
          end
          sleep(post_timeout) if post_timeout > 0
        rescue WaitError => e
          msg = timeout_message || e
          if screenshot_on_error
           sleep(retry_frequency)
           return screenshot_and_retry(msg, &block)
          else
           raise wait_error(msg)
         end
        rescue Exception => e
          handle_error_with_options(e, nil, screenshot_on_error)
        end
      end

      def screenshot_and_retry(msg, &block)
        path  = screenshot
        res = yield
        # Validate after taking screenshot
        if res
          FileUtils.rm_f(path)
          return res
        else
          embed(path, 'image/png', msg)
          raise wait_error(msg)
        end
      end

      def wait_poll(opts, &block)
        test = opts[:until]
        if test.nil?
          cond = opts[:until_exists]
          raise 'Must provide :until or :until_exists' unless cond
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
        if elements_arr.is_a?(String)
          elements_arr = [elements_arr]
        end
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
        options[:timeout] = options[:timeout] || 30
        options[:query] = options[:query] || "view"
        if options.has_key?(:condition)
          opt_condition = options[:condition]
          if opt_condition.is_a?(Symbol)
            target_condition = CALABASH_CONDITIONS[opt_condition]
          elsif opt_condition.is_a?(String)
            target_condition = options[:condition]
          end
          options[:condition] = target_condition
        end
        options[:condition] = options[:condition] || CALABASH_CONDITIONS[:none_animating]
        options[:post_timeout] = options[:post_timeout] || 0
        options[:frequency] = options[:frequency] || 0.3
        retry_frequency = options[:retry_frequency] = options[:retry_frequency] || 0.3
        options[:count] = options[:count] || 2
        timeout_message = options[:timeout_message] = options[:timeout_message] || "Timeout waiting for condition (#{options[:condition]})"
        screenshot_on_error = options[:screenshot_on_error] = options[:screenshot_on_error] || true

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
          msg = timeout_message || e
          if screenshot_on_error
            sleep(retry_frequency)
            return screenshot_and_retry(msg) do
              res = http({:method => :post, :path => 'condition'},
                         options)
              res = JSON.parse(res)
              res['outcome'] == 'SUCCESS'
            end
          else
            raise wait_error(msg)
          end
        rescue Exception => e
          handle_error_with_options(e,nil, options[:screenshot_on_error])
        end
      end

      def wait_for_none_animating(options = {})
        options[:condition] = CALABASH_CONDITIONS[:none_animating]
        wait_for_condition(options)
      end

      def wait_for_no_network_indicator(options = {})
        options[:condition] = CALABASH_CONDITIONS[:no_network_indicator]
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

      def wait_error(msg)
        (msg.is_a?(String) ? WaitError.new(msg) : msg)
      end


    end
  end
end
