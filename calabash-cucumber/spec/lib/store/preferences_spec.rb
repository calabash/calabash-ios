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

    describe "writing" do

      before do
        expect(store).to receive(:ensure_preferences_dir).and_call_original
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
  end

  describe "#generate_json" do

    it "can always generate JSON from defaults" do
      expect(store).not_to receive(:write_to_log)
      expect(store).not_to receive(:log_defaults_reset)

      expect(store.send(:generate_json, store.send(:defaults))).to be_truthy
    end

    describe "reverts to defaults when" do

      let(:hash) { {:a => 1} }
      let(:defaults) { {:b => 2 } }

      before do
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

  describe "#read" do
    it "calls write with defaults if file does not exist" do
      expect(File).to receive(:exist?).with(File.dirname(path)).and_return false
      expect(File).to receive(:exist?).with(path).and_return false
      expect(store).to receive(:write).and_call_original

      expect(store.send(:read)).to be == store.send(:defaults)
    end

    it "read the preferences.json file and returns a hash" do
       hash = { :b => 2 }

       FileUtils.mkdir_p(File.dirname(path))

       File.open(path, "w:UTF-8") do |file|
         file.write(JSON::generate(hash))
       end

       expect(store.send(:read)).to be == hash
    end
  end

  describe "#parse_json" do
    it "can always parse JSON generated from defaults" do
      string = JSON.pretty_generate(store.send(:defaults))

      expect(store).not_to receive(:write_to_log)
      expect(store).not_to receive(:log_defaults_reset)

      expect(store.send(:parse_json, string)).to be == store.send(:defaults)
    end

    describe "reverts to defaults when" do

      let(:defaults) { {:b => 2 } }
      let(:string) { JSON.pretty_generate(defaults) }
      let(:options) { {:symbolize_names => true } }

      before do
        expect(store).to receive(:defaults).and_return(defaults)
      end

      it "encounters a TypeError" do
        expect(JSON).to receive(:parse).with(string, options).and_raise TypeError

        expect(store.send(:parse_json, string)).to be == defaults
      end

      it "encounters a JSON::ParserError" do
        expect(JSON).to receive(:parse).with(string, options).and_raise JSON::ParserError

        expect(store.send(:parse_json, string)).to be == defaults
      end
    end
  end
end

