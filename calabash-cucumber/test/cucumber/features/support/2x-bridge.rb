module Calabash
  module Calabash2xBridge

    @@default_options = {
      timeout: RunLoop::Environment.ci? ? 16 : 8,
      retry_frequency: 0.1,
      exception_class: Timeout::Error
    }

    def wait_for_view(query, options={})
      default_options = @@default_options.dup
      merged_options = default_options.merge(options)

      unless merged_options[:message]
        message = %Q[
Waited #{merged_options[:timeout]} seconds for

 query("#{query}")

to match a view.

]
        merged_options[:timeout_message] = message
      end

      wait_for_element_exists(query, merged_options)
      query(query).first
    end

    def wait_for_no_view(query, options={})
      default_options = @@default_options.dup
      merged_options = default_options.merge(options)

      unless merged_options[:message]
        message = %Q[
Waited #{merged_options[:timeout]} seconds for

 query("#{query}")

to match no views.

]
        merged_options[:timeout_message] = message
      end

      wait_for_element_does_not_exist(query, merged_options)
    end

    def wait_for_animations
      wait_for_none_animating
    end

    def tap(query, options={})
      default_options = @@default_options.dup
      merged_options = default_options.merge(options)

      wait_for_view(query, merged_options)

      touch(query)
    end

    def uia_with_app(script)
      uia("UIATarget.localTarget().frontMostApp().#{script}")
    end

    # @!visibility private
    class PrivateWaitTimeoutError < RuntimeError ; end

    def with_timeout(timeout, timeout_message, exception_class = Timeout::Error, &block)
      if timeout_message.nil? ||
        (timeout_message.is_a?(String) && timeout_message.empty?)
        raise ArgumentError, 'You must provide a timeout message'
      end

      unless block_given?
        raise ArgumentError, 'You must provide a block'
      end

      # Timeout.timeout will never timeout if the given `timeout` is zero.
      # We will raise an exception if the timeout is zero.
      # Timeout.timeout already raises an exception if `timeout` is negative.
      if timeout == 0
        raise ArgumentError, 'Timeout cannot be 0'
      end

      message = if timeout_message.is_a?(Proc)
        timeout_message.call({timeout: timeout})
      else
        timeout_message
      end

      failed = false

      begin
        Timeout.timeout(timeout, PrivateWaitTimeoutError) do
          return block.call
        end
      rescue PrivateWaitTimeoutError => _
        # If we raise Timeout here the stack trace will be cluttered and we
        # wish to show the user a clear message, avoiding
        # "`rescue in with_timeout':" in the stack trace.
        failed = true
      end

      if failed
        fail(exception_class, message)
      end
    end

    def bridge_wait_for(timeout_message, options={}, &block)
      wait_options = @@default_options.merge(options)
      timeout = wait_options[:timeout]

      exception_class = wait_options[:exception_class]
      with_timeout(timeout, timeout_message, exception_class) do
        loop do
          value = block.call

          return value if value

          sleep(wait_options[:retry_frequency])
        end
      end
    end
  end
end

World(Calabash::Calabash2xBridge)
