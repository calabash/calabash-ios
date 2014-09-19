require 'run_loop'
require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber

    include Calabash::Cucumber::Logging

    # @!visibility private
    def self.const_missing(const_name)
      if const_name == :FRAMEWORK_VERSION
        _deprecated('0.9.169', 'FRAMEWORK_VERSION has been deprecated - there is no replacement', :warn)
        return nil
      end
      raise(NameError, "uninitialized constant Calabash::Cucumber::#{const_name}")
    end

    # A model of a release version that can be used to compare two version.
    #
    # Calabash tries very hard to comply with Semantic Versioning rules. However,
    # the semantic versioning spec is incompatible with RubyGem's patterns for
    # pre-release gems.
    #
    # > "But returning to the practical: No release version of SemVer is compatible with Rubygems." - _David Kellum_
    #
    # Calabash version numbers will be in the form `<major>.<minor>.<patch>[.pre<N>]`.
    #
    # @see http://semver.org/
    # @see http://gravitext.com/2012/07/22/versioning.html
    class Version < RunLoop::Version

    end
  end
end
