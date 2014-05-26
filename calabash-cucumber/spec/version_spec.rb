require 'spec_helper'

describe 'version module' do

  it 'should deprecate FRAMEWORK_VERSION cleanly' do
    expect(Calabash::Cucumber::FRAMEWORK_VERSION).to be == nil
  end

  it 'should handle non-defined constants with NameError' do
    expect{ Calabash::Cucumber::MISSING_CONSTANT }.to raise_error(NameError, 'uninitialized constant Calabash::Cucumber::MISSING_CONSTANT')
  end

end