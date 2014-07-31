module Calabash
  module Cucumber
    # IMPORTANT:  Developers, do not require this file anywhere.  Do not extend
    #             or include this module in any other class or module.

    # This module provides documentation for the environmental variables that
    # calabash-ios uses internally.
    #
    # @note The constants defined here are _stubs_ for documentation purposes.
    #
    # @note Do not require, include, or extend this module.
    module EnvironmentVariables

      # There are two strategies for passing UIA commands to the instruments
      # process:  `http` and `run_loop`.
      #
      # @note Mere mortals will never need to set the variable.  It is provided
      #  for developers who are trying to debug UIA communication problems.
      #
      # The `http` strategy uses a route in the embedded calabash server to
      # read/write commands to `NSUserDefaults standardUserDefaults` via the
      # `UIAApplication` preferences JS functions.  Since ~Nov 2013, this is the
      # default strategy and is by far faster than the `run_loop` strategy.
      #
      # The `run_loop` (AKA `host/cat`) strategy uses the
      # `UIAHost.performTaskWithPathArgumentsTimeout` to read/write commands to a
      # tmp file on the host computer.
      #
      # @raise [RuntimeError] if the value is not `http` or `run_loop`
      # @example
      #  UIA_STRATEGY=http cucumber
      #  UIA_STRATEGY=run_loop cucumber
      UIA_STRATEGY = 'http'


    end
  end
end