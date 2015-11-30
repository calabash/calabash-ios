require 'stringio'

describe 'calabash logging' do

  include Calabash::Cucumber::Logging

  it 'should output info messages' do
    info_msg = 'this is an info message'
    out = capture_stdout do
      calabash_info(info_msg)
    end
    expect(out.string).to be == "\e[32m\nINFO: #{info_msg}\e[0m\n"
  end

  it 'should output warning messages' do
    warn_msg = 'this is a warning message'
    out = capture_stderr do
      calabash_warn(warn_msg)
    end
    expect(out.string).to be == "\e[34m\nWARN: #{warn_msg}\e[0m\n"
  end

  it 'should output deprecated messages' do
    version = '0.9.169'
    dep_msg = 'this is a deprecation message'
    out = capture_stderr do
      _deprecated(version, dep_msg, :warn)
    end
    tokens = out.string.split("\n")
    expect("#{tokens[0]}\n#{tokens[1]}").to be == "\e[34m\nWARN: deprecated '#{version}' - #{dep_msg}"
    expect(tokens.count).to be > 5
    expect(tokens.count).to be < 9
  end

end

describe Calabash::Cucumber do
  describe ".colorize" do
    it "does nothing in win32 environments" do
      expect(Calabash::Cucumber).to receive(:windows_env?).and_return true

      actual = Calabash::Cucumber.send(:colorize, "string", 32)
      expect(actual).to be == "string"
    end

    it "does nothing on the XTC" do
      expect(Calabash::Cucumber).to receive(:windows_env?).and_return false
      expect(RunLoop::Environment).to receive(:xtc?).and_return true

      actual = Calabash::Cucumber.send(:colorize, "string", 32)
      expect(actual).to be == "string"
    end

    it "applies the color" do
      expect(Calabash::Cucumber).to receive(:windows_env?).and_return false
      expect(RunLoop::Environment).to receive(:xtc?).and_return false

      actual = Calabash::Cucumber.send(:colorize, "string", 32)
      expect(actual[/32/, 0]).not_to be == nil
    end
  end

  describe "logging" do
    before do
      allow(RunLoop::Environment).to receive(:debug?).and_return true
    end

    it ".log_warn" do
      Calabash::Cucumber.log_warn("warn")
    end

    it ".log_debug" do
      Calabash::Cucumber.log_debug("debug")
    end

    it ".log_error" do
      Calabash::Cucumber.log_error("error")
    end

    # .log_info is already taken by the XTC logger. (>_O)
    it ".log_info" do
      Calabash::Cucumber.log_info("info")
    end
  end
end
