require 'calabash-cucumber/utils/xctools'

# @todo 0.11.0 Remove this test when XcodeTools are deprecated
include Calabash::Cucumber::XcodeTools

describe 'xcode tools module' do

  describe 'developer directory' do
    it 'should respect the DEVELOPER_DIR env var' do
      original = ENV['DEVELOPER_DIR']
      begin
        ENV['DEVELOPER_DIR'] = '/foo/bar'
        expect(xcode_developer_dir).to be == ENV['DEVELOPER_DIR']
      ensure
        ENV['DEVELOPER_DIR'] = original
      end
    end

    it 'should return the default developer directory' do
      actual = `xcode-select --print-path`.chomp
      expect(xcode_developer_dir).to be == actual
    end

    it 'should deprecate xcode_bin_dir' do
      out = capture_stderr do
        xcode_bin_dir
      end
      expect(out.string.split(' ').include?('deprecated')).to be true
    end
  end

  describe 'instruments function' do

    it 'should check its arguments' do
      expect { instruments(:foo) }.to raise_error(ArgumentError)
    end

    it 'should report its version' do
      # Wonky!  RunLoop:XCTools#instruments :version returns a version object.
      # Our API expects a String.
      expect(instruments(:version)).to be_a String
    end

    it 'should be tell if it supports the -s flag' do
      expect(instruments_supports_hyphen_s?('5.1.1')).to be == true
    end

    it 'should be able to return a list of installed simulators' do
      expect(instruments(:sims)).to be_a Array
      expect(installed_simulators).to be_a Array
    end
  end
end
