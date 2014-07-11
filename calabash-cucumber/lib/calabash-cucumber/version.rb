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

    def self.const_missing(const_name)
      if const_name == :FRAMEWORK_VERSION
        _deprecated('0.9.169', 'FRAMEWORK_VERSION has been deprecated - there is no replacement', :warn)
        return nil
      end
      raise(NameError, "uninitialized constant Calabash::Cucumber::#{const_name}")
    end

    class Version

      attr_accessor :major
      attr_accessor :minor
      attr_accessor :patch
      attr_accessor :pre
      attr_accessor :pre_version

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

      def to_s
        str = [@major, @minor, @patch].join('.')
        str = "#{str}.#{@pre}" if @pre
        str
      end

      def == (other)
        compare(self, other) == 0
      end

      def != (other)
        compare(self, other) != 0
      end

      def < (other)
        compare(self, other) < 0
      end

      def > (other)
        compare(self, other) > 0
      end

      def <= (other)
        compare(self, other) <= 0
      end

      def >= (other)
        compare(self, other) >= 0
      end

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

if __FILE__ == $0
  require 'test/unit'

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
