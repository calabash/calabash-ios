require 'calabash-cucumber/core'
require 'calabash-cucumber/tests_helpers'
require 'fileutils'
require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber
    module WaitHelpers
      include Calabash::Cucumber::Logging
      include Calabash::Cucumber::Core
      include Calabash::Cucumber::TestsHelpers

      CLIENT_TIMEOUT_ADDITION = 5

      # `WaitError` is the error type raised
      # when a timeout occurs during a wait.
      # To handle a timeout without causing test failure use
      # @example
      #   begin
      #     ...
      #   rescue Calabash::Cucumber::WaitHelpers::WaitError => e
      #     ...
      #   end
      #
      class WaitError < RuntimeError
      end

      # Currently two conditions that can be
      # waited for using `wait_for_condition`: `:none_animating` no UIKit object is animating
      # and `:no_network_indicator` status bar network indicator not showing.
      CALABASH_CONDITIONS = {:none_animating => 'NONE_ANIMATING',
                             :no_network_indicator => 'NO_NETWORK_INDICATOR'}

      # The default options used in the "wait*" methods
      DEFAULT_OPTS = {
            # default upper limit on how long to wait
            :timeout => 30,
            # default polling frequency for waiting
            :retry_frequency => 0.3,
            # default extra wait after the condition becomes true
            :post_timeout => 0,
            # default message if timeout occurs
            :timeout_message => 'Timed out waiting...',
            # Calabash will generate a screenshot by default if waiting times out
            :screenshot_on_error => true
      }.freeze

      # Waits for a condition to be true. The condition is specified by a given block that is called repeatedly.
      # If the block returns a 'trueish' value the condition is considered true and
      # `wait_for` immediately returns.
      # There is a `:timeout` option that specifies a maximum number of seconds to wait.
      # If the given block doesn't return a 'trueish' value before the `:timeout` seconds has elapsed,
      # the waiting fails and raises a {Calabash::Cucumber::WaitHelpers::WaitError} error.
      #
      # The `options` hash
      # controls the details of waiting (see `options_or_timeout` below).
      # {Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS} specifies the default waiting options.
      #
      # `wait_for` is a low-level building-block for waiting and often there are higher-level
      # waiting methods what use `wait_for` in their implementation (e.g. `wait_for_element_exists`).
      # @see #wait_for_element_exists
      #
      # @example Waiting for an element (see also `wait_for_element_exists`)
      #   wait_for(timeout: 60,
      #            timeout_message: "Could not find 'Sign in' button") do
      #     element_exists("button marked:'Sign in'")
      #   end
      # @param [Hash] options_or_timeout options for controlling the details of the wait.
      #   Note for backwards compatibility with old Calabash versions can also be a number which is
      #   then interpreted as a timeout.
      # @option options_or_timeout [Numeric] :timeout (30) upper limit on how long to wait (in seconds)
      # @option options_or_timeout [Numeric] :retry_frequency (0.3) how often to poll (i.e., call the given block)
      # @option options_or_timeout [Numeric] :post_timeout (0) if positive, an extra wait is made after the condition
      #   is satisfied
      # @option options_or_timeout [String] :timeout_message the error message to use if condition is not satisfied
      #   in time
      # @option options_or_timeout [Boolean] :screenshot_on_error generate a screenshot on error
      # @return [nil] when the condition is satisfied
      # @raise [Calabash::Cucumber::WaitHelpers::WaitError] when the timeout is exceeded
      def wait_for(options_or_timeout=DEFAULT_OPTS, &block)
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

      # Repeatedly runs an action (for side-effects) until a condition is satisfied.
      # Similar to `wait_for` but specifies both a condition to wait for and an action to repeatedly perform
      # to make the condition true (e.g. scrolling). The return value of the action is ignored.
      #
      # The block represents the action and options :until or :until_exists specify the condition to wait for.
      # Same options as `wait_for` can be provided.
      #
      # @see #wait_for
      #
      # @example Scrolling until we find an element
      #   wait_poll(timeout: 10,
      #             timeout_message: 'Unable to find "Example"',
      #             until_exists: "* marked:'Example'") do
      #     scroll("tableView", :down)
      #   end
      #
      # @example Win the battle
      #   wait_poll(timeout: 60,
      #             timeout_message: 'Defeat!',
      #             until: lambda { enemy_defeated? }) do
      #     launch_the_missiles!
      #   end
      # @param [Hash] opts options for controlling the details of the wait in addition to the options specified below,
      #   all options in {Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS} also apply and can be overridden.
      # @option opts [Proc] :until if specified this lambda/Proc becomes the condition to wait for.
      # @option opts [String] :until_exists if specified, a calabash query to wait for. Exactly one of `:until` and
      #   `:until_exists` must be specified
      # @return [nil] when the condition is satisfied
      # @raise [Calabash::Cucumber::WaitHelpers::WaitError] when the timeout is exceeded
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

      # Waits for a Calabash query to return a non-empty result (typically a UI element to be visible).
      # Uses `wait_for`.
      # @see #wait_for
      # @see Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS
      #
      # @example Waiting for an element to be visible
      #   wait_for_element_exists("button marked:'foo'", timeout: 60)
      # @param [String] element_query a Calabash query to wait for (i.e. `element_exists(element_query)`)
      # @param [Hash] options options for controlling the details of the wait.
      #   The same options as {Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS} apply.
      # @return [nil] when the condition is satisfied
      # @raise [Calabash::Cucumber::WaitHelpers::WaitError] when the timeout is exceeded
      def wait_for_element_exists(element_query, options={})
        options[:timeout_message] = options[:timeout_message] || "Timeout waiting for element: #{element_query}"
        wait_for(options) { element_exists(element_query) }
      end

      # Waits for one or more Calabash queries to all return non-empty results (typically a UI elements to be visible).
      # Uses `wait_for`.
      # @see #wait_for
      # @see #wait_for_element_exists
      # @see Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS
      #
      # @param [Array<String>] elements_arr an Array of Calabash queries to wait for (i.e. `element_exists(element_query)`)
      # @param [Hash] options options for controlling the details of the wait.
      #   The same options as {Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS} apply.
      # @return [nil] when the condition is satisfied
      # @raise [Calabash::Cucumber::WaitHelpers::WaitError] when the timeout is exceeded
      def wait_for_elements_exist(elements_arr, options={})
        if elements_arr.is_a?(String)
          elements_arr = [elements_arr]
        end
        options[:timeout_message] = options[:timeout_message] || "Timeout waiting for elements: #{elements_arr.join(',')}"
        wait_for(options) do
          elements_arr.all? { |q| element_exists(q) }
        end
      end

      # Waits for a Calabash query to return an empty result (typically a UI element to disappear).
      # Uses `wait_for`.
      # @see #wait_for
      # @see #wait_for_element_exists
      # @see Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS
      #
      # @param [String] element_query a Calabash query to be empty (i.e. `element_does_not_exist(element_query)`)
      # @param [Hash] options options for controlling the details of the wait.
      #   The same options as {Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS} apply.
      # @return [nil] when the condition is satisfied
      # @raise [Calabash::Cucumber::WaitHelpers::WaitError] when the timeout is exceeded
      def wait_for_element_does_not_exists(element_query, options={})
        options[:timeout_message] = options[:timeout_message] || "Timeout waiting for element to not exist: #{element_query}"
        wait_for(options) { element_does_not_exist(element_query) }
      end

      # Waits for one or more Calabash queries to all return empty results (typically a UI elements to disappear).
      # Uses `wait_for`.
      # @see #wait_for
      # @see #wait_for_element_exists
      # @see #wait_for_element_does_not_exists
      # @see Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS
      #
      # @param [Array<String>] elements_arr an Array of Calabash queries to be empty (i.e. `element_does_not_exist(element_query)`)
      # @param [Hash] options options for controlling the details of the wait.
      #   The same options as {Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS} apply.
      # @return [nil] when the condition is satisfied
      # @raise [Calabash::Cucumber::WaitHelpers::WaitError] when the timeout is exceeded
      def wait_for_elements_do_not_exist(elements_arr, options={})
        if elements_arr.is_a?(String)
          elements_arr = [elements_arr]
        end
        options[:timeout_message] = options[:timeout_message] || "Timeout waiting for no elements matching: #{elements_arr.join(",")}"
        wait_for(options) do
          elements_arr.none? { |q| element_exists(q) }
        end
      end

      # @!visibility private
      def wait_for_condition(options = {})
        timeout = options[:timeout]
        unless timeout && timeout > 0
          timeout = 30
        end
        options[:query] = options[:query] || '*'
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

        retry_frequency = options[:frequency] = options[:frequency] || 0.2
        timeout_message = options[:timeout_message] = options[:timeout_message] || "Timeout waiting (#{options[:timeout]}) for condition (#{options[:condition]})"
        screenshot_on_error = true
        if options.key?(:screenshot_on_error)
          screenshot_on_error = options[:screenshot_on_error]
        end

        begin
          Timeout::timeout(timeout+CLIENT_TIMEOUT_ADDITION, WaitError) do
            res = http({:method => :post, :path => 'condition'},
                       options)
            res = JSON.parse(res)
            unless res['outcome'] == 'SUCCESS'
              raise WaitError.new(res['reason'])
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
          handle_error_with_options(e,nil, screenshot_on_error)
        end
      end

      # Waits for all elements to stop animating (EXPERIMENTAL).
      # @param [Hash] options options for controlling the details of the wait.
      # @option options [Numeric] :timeout (30) maximum time to wait
      # @return [nil] when the condition is satisfied
      # @raise [Calabash::Cucumber::WaitHelpers::WaitError] when the timeout is exceeded
      def wait_for_none_animating(options = {})
        options[:condition] = CALABASH_CONDITIONS[:none_animating]
        wait_for_condition(options)
      end

      # Waits for the status-bar network indicator to stop animating (network activity done).
      # @param [Hash] options options for controlling the details of the wait.
      # @option options [Numeric] :timeout (30) maximum time to wait
      # @return [nil] when the condition is satisfied
      # @raise [Calabash::Cucumber::WaitHelpers::WaitError] when the timeout is exceeded
      def wait_for_no_network_indicator(options = {})
        options[:condition] = CALABASH_CONDITIONS[:no_network_indicator]
        wait_for_condition(options)
      end

      # Combines waiting for elements and waiting for animations.
      # @param [Array] done_queries Calabash queries to wait for (one or more).
      # @param [Hash]  check_options ({}) options used for `wait_for_elements_exists(done_queries, check_options)`
      # @param [Hash]  animation_options ({}) options used for `wait_for_none_animating(animation_options)`
      def wait_for_transition(done_queries, check_options={},animation_options={})
        done_queries = [*done_queries]
        wait_for_elements_exist(done_queries,check_options)
        wait_for_none_animating(animation_options)
      end

      # Combines touching an element and `wait_for_transition`
      # @see #wait_for_transition
      # @param [String] touch_q the Calabash query to touch
      # @param [Array] done_queries passed to `wait_for_transition`
      # @param [Hash]  check_options ({}) passed to `wait_for_transition`
      # @param [Hash]  animation_options ({}) passed to `wait_for_transition`
      def touch_transition(touch_q, done_queries,check_options={},animation_options={})
        touch(touch_q)
        wait_for_transition(done_queries,check_options,animation_options)
      end

      # Performs a lambda action until the element (a query string) appears.
      # The default action is to do nothing. Similar to `wait_poll`.
      #
      # Raises an error if no uiquery is specified.
      #
      # @see #wait_poll
      #
      # @example
      #   until_element_exists("button", :action => lambda { swipe("up") })
      # @param [String] uiquery the Calabash query to wait for
      # @param [Hash] opts options for controlling the details of the wait.
      #   The same options as {Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS} apply.
      def until_element_exists(uiquery, opts = {})
        extra_opts = { :until_exists => uiquery, :action => lambda {} }
        opts = DEFAULT_OPTS.merge(extra_opts).merge(opts)
        wait_poll(opts) do
          opts[:action].call
        end
      end

      # Performs a lambda action until the element (a query string) disappears.
      # The default action is to do nothing. 
      #
      # Raises an error if no uiquery is specified.
      #
      # @example
      #   until_element_does_not_exist("button", :action => lambda { swipe("up") })
      # @see #wait_poll
      # @param [String] uiquery the Calabash query to wait for disappearing.
      # @param [Hash] opts options for controlling the details of the wait.
      #   The same options as {Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS} apply.
      def until_element_does_not_exist(uiquery, opts = {})
        condition = lambda {element_does_not_exist(uiquery)}
        extra_opts = { :until => condition, :action => lambda {} }
        opts = DEFAULT_OPTS.merge(extra_opts).merge(opts)
        wait_poll(opts) do
          opts[:action].call
        end
      end

      # Performs a lambda action once the element exists.
      # The default behavior is to touch the specified element.
      #
      # Raises an error if no uiquery is specified.
      #
      # @example
      #   when_element_exists("button", :timeout => 10)
      # @see #wait_for
      # @param [String] uiquery the Calabash query to wait for.
      # @param [Hash] opts options for controlling the details of the wait.
      #   The same options as {Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS} apply.
      def when_element_exists(uiquery, opts = {})
        action = opts[:action] || lambda { touch(uiquery) }
        wait_for_element_exists(uiquery, opts)
        action.call
      end

      # @!visibility private
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

      # @!visibility private
      # raises an error by raising a exception and conditionally takes a
      # screenshot based on the value of +screenshot_on_error+.
      # @param [Exception,nil] ex an exception to raise
      # @param [String,nil] timeout_message the message of the raise
      # @param [Boolean] screenshot_on_error iff true takes a screenshot before
      #  raising an error
      # @return [nil]
      # @raise RuntimeError based on +ex+ and +timeout_message+
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

      # @private
      # if +msg+ is a String, a new WaitError is returned. Otherwise +msg+
      # itself is returned.
      # @param [String,Object] msg a message to raise
      # @return [WaitError] if +msg+ is a String, returns a new WaitError
      # @return [Object] if +msg+ is anything else, returns +msg+
      def wait_error(msg)
        (msg.is_a?(String) ? WaitError.new(msg) : msg)
      end

    end
  end
end
