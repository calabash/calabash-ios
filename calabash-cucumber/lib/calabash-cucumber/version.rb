require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber

    # @!visibility public
    # The Calabash iOS gem version.
    VERSION = '0.10.0.pre1'

    # @!visibility public
    # The minimum required version of the calabash.framework or, for Xamarin
    # users, the Calabash component.
    MIN_SERVER_VERSION = '0.10.0.pre1'

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
    # Calabash tries very hard to comply with Semantic Versioning rules.
    #
    # However, our test workflow requires that we use `.pre` to denote
    # pre-release versions instead of the recommended `-alpha`, `-beta`, or, `-pre`.
    #
    # Calabash version numbers will be in the form `<major>.<minor>.<patch>[.pre<N>]`.
    #
    # @see http://semver.org/
    class Version

      # @!attribute [rw] major
      #   @return [Integer] the major version
      attr_accessor :major

      # @!attribute [rw] minor
      #   @return [Integer] the minor version
      attr_accessor :minor

      # @!attribute [rw] patch
      #   @return [Integer] the patch version
      attr_accessor :patch

      # @!attribute [rw] pre
      #   @return [Boolean] true iff this is a pre-release version
      attr_accessor :pre

      # @!attribute [rw] pre_version
      #   @return [Integer] if this is a pre-release version, returns the
      #     pre-release version; otherwise this is nil
      attr_accessor :pre_version

      # Creates a new Version instance with all the attributes set.
      #
      # @example
      #  version = Version.new(0.10.1)
      #  version.major       => 0
      #  version.minor       => 10
      #  version.patch       => 1
      #  version.pre         => false
      #  version.pre_release => nil
      #
      # @example
      #  version = Version.new(1.6.3.pre5)
      #  version.major       => 1
      #  version.minor       => 6
      #  version.patch       => 3
      #  version.pre         => true
      #  version.pre_release => 5
      #
      # @param [String] version the version string to parse.
      def initialize(version)
        tokens = version.split('.')
        count = tokens.count
        if count == 4
          @pre = tokens[3]
          pre_tokens = @pre.scan(/\D+|\d+/)
          @pre_version = pre_tokens[1].to_i if pre_tokens.count == 2
        end

        @major, @minor, @patch = version.split('.').map(&:to_i)
      end

      # Returns an string representation of this version.
      # @return [String] a string in the form `<major>.<minor>.<patch>[.pre<N>]`
      def to_s
        str = [@major, @minor, @patch].join('.')
        str = "#{str}.#{@pre}" if @pre
        str
      end

      # Compare this version to another for equality.
      # @param [Version] other the version to compare against
      # @return [Boolean] true iff this Version is the same as `other`
      def == (other)
        compare(self, other) == 0
      end

      # Compare this version to another for inequality.
      # @param [Version] other the version to compare against
      # @return [Boolean] true iff this Version is not the same as `other`
      def != (other)
        compare(self, other) != 0
      end

      # Is this version less-than another version?
      # @param [Version] other the version to compare against
      # @return [Boolean] true iff this Version is less-than `other`
      def < (other)
        compare(self, other) < 0
      end

      # Is this version greater-than another version?
      # @param [Version] other the version to compare against
      # @return [Boolean] true iff this Version is greater-than `other`
      def > (other)
        compare(self, other) > 0
      end

      # Is this version less-than or equal to another version?
      # @param [Version] other the version to compare against
      # @return [Boolean] true iff this Version is less-than or equal `other`
      def <= (other)
        compare(self, other) <= 0
      end

      # Is this version greater-than or equal to another version?
      # @param [Version] other the version to compare against
      # @return [Boolean] true iff this Version is greater-than or equal `other`
      def >= (other)
        compare(self, other) >= 0
      end

      # Compare version `a` to version `b`.
      #
      # @example
      #   compare Version.new(0.10.0), Version.new(0.9.0)  =>  1
      #   compare Version.new(0.9.0),  Version.new(0.10.0) => -1
      #   compare Version.new(0.9.0),  Version.new(0.9.0)  =>  0
      #
      # @return [Integer] an integer `(-1, 1)`
      def compare(a, b)

        if a.major != b.major
          return a.major > b.major ? 1 : -1
        end

        if a.minor != b.minor
          return a.minor > b.minor ? 1 : -1
        end

        if a.patch != b.patch
          return a.patch > b.patch ? 1 : -1
        end

        return 1 if a.pre and (not b.pre)
        return -1 if (not a.pre) and b.pre

        return 1 if a.pre_version and (not b.pre_version)
        return -1 if (not a.pre_version) and b.pre_version

        if a.pre_version != b.pre_version
          return a.pre_version > b.pre_version ? 1 : -1
        end

        0

      end
    end
  end
end

# These are unit tests.
#
# $ ruby lib/calabash-cucumber/version.rb
#
# todo move to rspec
if __FILE__ == $0
  require 'test/unit'

  # @!visibility private
  class LocalTest < Test::Unit::TestCase
    include Calabash::Cucumber

    def test_version
      a = Version.new('0.9.169')
      assert_equal(0, a.major)
      assert_equal(9, a.minor)
      assert_equal(169, a.patch)
      assert_nil(a.pre)
      assert_nil(a.pre_version)
    end

    def test_unnumbered_prerelease
      a = Version.new('0.9.169.pre')
      assert_equal('pre', a.pre)
      assert_nil(a.pre_version)
    end

    def test_numbered_prerelease
      a = Version.new('0.9.169.pre1')
      assert_equal('pre1', a.pre)
      assert_equal(1, a.pre_version)
    end

    def test_compare_equal
      a = Version.new('0.9.169')
      b = Version.new('0.9.169')
      assert(a == b)

      a = Version.new('0.9.169.pre')
      b = Version.new('0.9.169.pre')
      assert(a == b)

      a = Version.new('0.9.169.pre2')
      b = Version.new('0.9.169.pre2')
      assert(a == b)

    end

    def test_compare_not_equal
      a = Version.new('0.9.168')
      b = Version.new('0.9.169')
      assert(a != b)


      a = Version.new('0.9.169')
      b = Version.new('0.9.169.pre1')
      assert(a != b)

      a = Version.new('0.9.169.pre')
      b = Version.new('0.9.169.pre1')
      assert(a != b)

      a = Version.new('0.9.169.pre1')
      b = Version.new('0.9.169.pre2')
      assert(a != b)
    end

    def test_compare_lt
      a = Version.new('0.9.168')
      b = Version.new('0.9.169')
      assert(a < b)

      a = Version.new('0.9.169')
      b = Version.new('0.9.169.pre')
      assert(a < b)

      a = Version.new('0.9.169.pre')
      b = Version.new('0.9.169.pre1')
      assert(a < b)

      a = Version.new('0.9.169.pre1')
      b = Version.new('0.9.169.pre2')
      assert(a < b)
    end

    def test_compare_gt
      a = Version.new('0.9.169')
      b = Version.new('0.9.168')
      assert(a > b)

      a = Version.new('0.9.169.pre')
      b = Version.new('0.9.169')
      assert(a > b)

      a = Version.new('0.9.169.pre1')
      b = Version.new('0.9.169.pre')
      assert(a > b)

      a = Version.new('0.9.169.pre2')
      b = Version.new('0.9.169.pre1')
      assert(a > b)
    end

    def test_compare_lte
      a = Version.new('0.9.168')
      b = Version.new('0.9.169')
      assert(a <= b)
      a = Version.new('0.9.169')
      assert(a <= b)
    end

    def test_compare_gte
      a = Version.new('0.9.169')
      b = Version.new('0.9.168')
      assert(a >= b)
      b = Version.new('0.9.169')
      assert(a >= b)
    end

  end
end
