describe Calabash::Cucumber::Preferences do

  let(:tmp_dir) { File.expand_path("tmp") }
  let(:store) { Calabash::Cucumber::Preferences.new }
  let(:path) { File.join(tmp_dir, "preferences", "preferences.json") }

  before do
    FileUtils.rm_rf(tmp_dir)
    allow(Calabash::Cucumber::DotDir).to receive(:directory).and_return(tmp_dir)
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

  describe "#write" do
    describe "raises error when" do
      it "is passed nil" do
        expect do
          store.send(:write, nil)
        end.to raise_error ArgumentError, /cannot be nil/
      end

      it "is passed a non-Hash object" do
        expect do
          store.send(:write, [])
        end.to raise_error ArgumentError, /Expected a Hash/
      end

      it "is passed an empty Hash" do
        expect do
          store.send(:write, {})
        end.to raise_error ArgumentError, /Hash to write cannot be empty/
      end
    end

    it "writes the hash to a file as JSON" do
      hash = { :a => 1, :b => 2 }
      store.send(:write, hash)
      string = File.read(path).force_encoding("UTF-8")

      expect(JSON.parse(string, {:symbolize_names => true })).to be == hash
    end

    it "can always write defaults" do
      hash = store.send(:defaults)
      store.send(:write, hash)
      string = File.read(path).force_encoding("UTF-8")

      expect(JSON.parse(string, {:symbolize_names => true })).to be == hash
    end
  end

  describe "#generate_json" do
    let(:hash) { {:a => 1} }

    it "can always generate JSON from defaults" do
      expect(store.send(:generate_json, store.send(:defaults))).to be_truthy
    end

    describe "reverts to defaults when" do

      let(:defaults) { {:b => 2 } }

      before do
        defaults = { :b  => 2 }
        expect(store).to receive(:defaults).and_return(defaults)
        expect(JSON).to receive(:pretty_generate).with(defaults).and_call_original
      end

      it "encounters a TypeError" do
        expect(JSON).to receive(:pretty_generate).with(hash).and_raise TypeError

        expect(store.send(:generate_json, hash)).to be_truthy
      end

      it "encounters a JSON::UnparserError" do
        expect(JSON).to receive(:pretty_generate).with(hash).and_raise JSON::UnparserError

        expect(store.send(:generate_json, hash)).to be_truthy
      end
    end
  end
end

