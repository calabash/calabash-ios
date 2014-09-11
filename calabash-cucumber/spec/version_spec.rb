require 'spec_helper'
require 'calabash-cucumber'

describe 'version module' do

  it 'should deprecate FRAMEWORK_VERSION cleanly' do
    val = nil
    out = capture_stderr do
      # noinspection RubyResolve
      val = Calabash::Cucumber::FRAMEWORK_VERSION
    end
    expect(out.string).not_to be == nil
    expect(out.string).not_to be == ''
    expect(val).to be == nil
  end

  it 'should handle non-defined constants with NameError' do
    expect{ Calabash::Cucumber::MISSING_CONSTANT }.to raise_error(NameError, 'uninitialized constant Calabash::Cucumber::MISSING_CONSTANT')
  end

end