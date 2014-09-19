require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber

    # @!visibility public
    # The Calabash iOS gem version.
    VERSION = '0.10.1'

    # @!visibility public
    # The minimum required version of the calabash.framework or, for Xamarin
    # users, the Calabash component.
    MIN_SERVER_VERSION = '0.10.1'

    # @!visibility private
    def self.const_missing(const_name)
      if const_name == :FRAMEWORK_VERSION
        _deprecated('0.9.169', 'FRAMEWORK_VERSION has been deprecated - there is no replacement', :warn)
        return nil
      end
      raise(NameError, "uninitialized constant Calabash::Cucumber::#{const_name}")
    end
  end
end
