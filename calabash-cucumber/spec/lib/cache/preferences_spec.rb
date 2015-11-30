describe Calabash::Cucumber::Preferences do

  before do
    path = Dir.mktmpdir
    allow(Calabash::Cucumber::DotDir).to receive(:directory).and_return(path)
  end

  it ".preferences" do
    prefs = Calabash::Cucumber::Preferences.send(:preferences)

    expect(prefs).to be_a_kind_of(Calabash::Cucumber::Preferences)
    expect(Calabash::Cucumber::Preferences.class_variable_get(:@@preferences)).to be == prefs
  end
end

