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
