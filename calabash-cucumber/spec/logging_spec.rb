require 'spec_helper'
require 'stringio'

describe 'calabash logging' do

  include Calabash::Cucumber::Logging

  it 'should output info messages' do
    info_msg = 'this is an info message'
    calabash_info(info_msg)
    out = capture_stdout do
      calabash_info(info_msg)
    end
    expect(out.string).to be == "\e[32m\nINFO: #{info_msg}\e[0m\n"
  end

  it 'should output warning messages' do
    warn_msg = 'this is a warning message'
    calabash_warn(warn_msg)
    out = capture_stderr do
      calabash_warn(warn_msg)
    end
    expect(out.string).to be == "\e[34m\nWARN: #{warn_msg}\e[0m\n"
  end

  it 'should output deprecated messages' do
    version = '0.9.169'
    dep_msg = 'this is a deprecation message'
    _deprecated(version, dep_msg, :warn)
    out = capture_stderr do
      _deprecated(version, dep_msg, :warn)
    end
    tokens = out.string.split("\n")
    expect("#{tokens[0]}\n#{tokens[1]}").to be == "\e[34m\nWARN: deprecated '#{version}' - '#{dep_msg}'"
    expect(tokens.count).to be >= 6
  end

end