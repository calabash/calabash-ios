describe Calabash::Cucumber::Preferences do

  let(:tmp_dir) { File.expand_path("tmp") }
  let(:store) { Calabash::Cucumber::Preferences.new }
  let(:path) { File.join(tmp_dir, "preferences", "preferences.json") }

  before do
    allow(Calabash::Cucumber::DotDir).to receive(:directory).and_return(tmp_dir)
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe ".new" do
    it "sets the @path variable" do
      expect(store.instance_variable_get(:@path)).to be == path
      expect(store.send(:path)).to be == path
    end

    it "ensures the path exists" do
      expect(File.exist?(store.send(:path))).to be_truthy
    end
  end
end

