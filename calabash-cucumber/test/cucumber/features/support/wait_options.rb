require 'calabash-cucumber/wait_helpers'

module LPExample
  module WaitOpts

    include Calabash::Cucumber::WaitHelpers

    # a convenience function for passing wait options to a wait_for* function
    # @return [Hash] default wait options
    #
    # pass this to your wait_for_* functions
    #
    # @param [String] view_desc a meaningful description of the view you are waiting for
    # @param [Hash] opts wait options
    # @option opts :timeout defaults to _wait_timeout()
    # @option opts :disappear iff true changes the error message to indicate
    #   that we were waiting for the view to disappear
    def wait_options(view_desc, opts={})
      default_opts = {:disappear => false,
                      :timeout => wait_timeout}
      merged = default_opts.merge(opts)

      # handle :timeout => nil
      timeout = merged[:timeout] || wait_timeout
      if merged[:disappear]
        msg = "waited for #{timeout} s but could still see '#{view_desc}'"
      else
        msg = "waited for #{timeout} s but did not see '#{view_desc}'"
      end

      {:timeout => timeout,
       :retry_frequency => retry_freq,
       :post_timeout => wait_step_pause,
       :timeout_message => msg}
    end

    # pause cucumber execution for a moment; after a touch for example
    # @param [Float] duration (0.4) time to sleep
    def step_pause(duration=nil)
      sleep((duration || ENV['STEP_PAUSE'] || 0.4).to_f)
    end

    # how long to wait for a view before failing
    def wait_timeout
      (ENV['WAIT_TIMEOUT'] || 8.0).to_f
    end

    # how often to retry querying for a view
    def retry_freq
      (ENV['RETRY_FREQ'] || 0.1).to_f
    end

    # the time to wait after a wait condition evals to +true+
    def wait_step_pause
      (ENV['POST_TIMEOUT'] || 0.0).to_f
    end
  end
end

World(LPExample::WaitOpts)

