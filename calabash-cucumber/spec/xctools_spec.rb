require 'calabash-cucumber/utils/xctools'

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

    it 'should find the developer usr/bin directory' do
      actual = File.join(xcode_developer_dir, '/usr/bin')
      expect(xcode_bin_dir).to be == "#{actual}"
      expect(File.exists?("#{xcode_bin_dir}/xcodebuild")).to be == true
    end
  end

  describe 'instruments function' do

    it 'should find the binary' do
      actual = File.join(xcode_bin_dir, 'instruments')
      expect(instruments).to be == actual
    end

    it 'should check its arguments' do
      expect { instruments(:foo) }.to raise_error(ArgumentError)
    end

    it 'should report its version' do
      version = instruments(:version)
      expect(['5.1.1', '5.1'].include?(version)).to be == true
    end

    it 'should be tell if it supports the -s flag' do
      expect(instruments_supports_hyphen_s?('5.1.1')).to be == true
      expect(instruments_supports_hyphen_s?('5.1')).to be == true
      expect(instruments_supports_hyphen_s?('5.0.2')).to be == false
      expect(instruments_supports_hyphen_s?('4.6.3')).to be == false
    end

    it 'should be able to return a list of installed simulators' do
      sims = instruments(:sims)
      expect(installed_simulators).to be == sims
    end
  end
end
