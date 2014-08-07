require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber

    # @!visibility public
    # The Calabash iOS gem version.
    VERSION = '0.10.0.pre5'

    # @!visibility public
    # The minimum required version of the calabash.framework or, for Xamarin
    # users, the Calabash component.
    MIN_SERVER_VERSION = '0.10.0.pre4'

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
      #   @return [Boolean] true if this is a pre-release version
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
      # @raise [ArgumentError] if version is not in the form 5, 6.1, 7.1.2, 8.2.3.pre1
      def initialize(version)
        tokens = version.strip.split('.')
        count = tokens.count
        if tokens.empty?
          raise ArgumentError, "expected '#{version}' to be like 5, 6.1, 7.1.2, 8.2.3.pre1"
        end

        if count < 4 and tokens.any? { |elm| elm =~ /\D/ }
          raise ArgumentError, "expected '#{version}' to be like 5, 6.1, 7.1.2, 8.2.3.pre1"
        end

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
        str = [@major, @minor, @patch].compact.join('.')
        str = "#{str}.#{@pre}" if @pre
        str
      end

      # Compare this version to another for equality.
      # @param [Version] other the version to compare against
      # @return [Boolean] true if this Version is the same as `other`
      def == (other)
        Version.compare(self, other) == 0
      end

      # Compare this version to another for inequality.
      # @param [Version] other the version to compare against
      # @return [Boolean] true if this Version is not the same as `other`
      def != (other)
        Version.compare(self, other) != 0
      end

      # Is this version less-than another version?
      # @param [Version] other the version to compare against
      # @return [Boolean] true if this Version is less-than `other`
      def < (other)
        Version.compare(self, other) < 0
      end

      # Is this version greater-than another version?
      # @param [Version] other the version to compare against
      # @return [Boolean] true if this Version is greater-than `other`
      def > (other)
        Version.compare(self, other) > 0
      end

      # Is this version less-than or equal to another version?
      # @param [Version] other the version to compare against
      # @return [Boolean] true if this Version is less-than or equal `other`
      def <= (other)
        Version.compare(self, other) <= 0
      end

      # Is this version greater-than or equal to another version?
      # @param [Version] other the version to compare against
      # @return [Boolean] true if this Version is greater-than or equal `other`
      def >= (other)
        Version.compare(self, other) >= 0
      end

      # Compare version `a` to version `b`.
      #
      # @example
      #   compare Version.new(0.10.0), Version.new(0.9.0)  =>  1
      #   compare Version.new(0.9.0),  Version.new(0.10.0) => -1
      #   compare Version.new(0.9.0),  Version.new(0.9.0)  =>  0
      #
      # @return [Integer] an integer `(-1, 1)`
      def self.compare(a, b)

        if a.major != b.major
          return a.major > b.major ? 1 : -1
        end

        if a.minor != b.minor
          return a.minor.to_i  > b.minor.to_i ? 1 : -1
        end

        if a.patch != b.patch
          return a.patch.to_i > b.patch.to_i ? 1 : -1
        end

        return 1 if a.pre and (not b.pre)
        return -1 if (not a.pre) and b.pre

        return 1 if a.pre_version and (not b.pre_version)
        return -1 if (not a.pre_version) and b.pre_version

        if a.pre_version != b.pre_version
          return a.pre_version.to_i > b.pre_version.to_i ? 1 : -1
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
  # Unit testing of Version class
  class LocalTest < Test::Unit::TestCase
    include Calabash::Cucumber

    # @!visibility private
    def test_version
      a = Version.new('0.9.169')
      assert_equal(0, a.major)
      assert_equal(9, a.minor)
      assert_equal(169, a.patch)
      assert_nil(a.pre)
      assert_nil(a.pre_version)
    end

    def test_new_passed_invalid_arg

      assert_raise(ArgumentError) { Version.new(' ') }
      assert_raise(ArgumentError) { Version.new('5.1.pre3') }
      assert_raise(ArgumentError) { Version.new('5.pre2') }

    end

    # @!visibility private
    def test_unnumbered_prerelease
      a = Version.new('0.9.169.pre')
      assert_equal('pre', a.pre)
      assert_nil(a.pre_version)
    end

    # @!visibility private
    def test_numbered_prerelease
      a = Version.new('0.9.169.pre1')
      assert_equal('pre1', a.pre)
      assert_equal(1, a.pre_version)
    end

    # @!visibility private
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

    # @!visibility private
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

    # @!visibility private
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

    # @!visibility private
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

    # @!visibility private
    def test_compare_lte
      a = Version.new('0.9.168')
      b = Version.new('0.9.169')
      assert(a <= b)
      a = Version.new('0.9.169')
      assert(a <= b)
    end

    # @!visibility private
    def test_compare_gte
      a = Version.new('0.9.169')
      b = Version.new('0.9.168')
      assert(a >= b)
      b = Version.new('0.9.169')
      assert(a >= b)
    end

    def test_compare_missing_patch_level
      a = Version.new('6.0')
      b = Version.new('5.1.1')
      assert(Version.compare(a, b) == 1)
      assert(a > b)

      a = Version.new('5.1.1')
      b = Version.new('6.0')
      assert(Version.compare(a, b) == -1)
      assert(a < b)
    end

    def test_compare_missing_minor_level
      a = Version.new('5.1')
      b = Version.new('5.1.1')
      assert(Version.compare(a, b) == -1)
      assert(a < b)

      a = Version.new('5.1.1')
      b = Version.new('5.1')
      assert(Version.compare(a, b) == 1)
      assert(a > b)
    end

  end
end
