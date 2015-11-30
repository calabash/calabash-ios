describe Calabash::Cucumber::Cache do

  let(:tmp_dir) { Dir.mktmpdir }
  let(:path) { File.join(tmp_dir, "cache.file") }
  let(:cache) { Calabash::Cucumber::Cache.new(path) }
  let(:default) { { a: 1, b:2 } }

  before do
    allow(cache).to receive(:default_cache).and_return(default)
  end

  it ".new" do
    expect(cache.instance_variable_get(:@path)).to be == path
  end

  it "#clear" do
    expect(cache).to receive(:write).with(default).and_return(default)

    expect(cache.clear).to be == default
  end

  it "#to_s" do
    puts cache
  end

  describe "#read" do
    it "reads cache if it exists" do
      FileUtils.touch(path)
      expect(Marshal).to receive(:load).and_return({})

      expect(cache.read).to be == {}
    end

    it "creates a new cache if one does not exist" do
      FileUtils.rm_rf(path)
      expect(cache).to receive(:write).with(default).and_call_original

      expect(cache.read).to be == default
    end
  end

  # private

  it "#path" do
    expect(cache.send(:path)).to be == path
  end

  describe "#write" do
    describe "raises error when" do
      it "is passed nil" do
        expect do
          cache.send(:write, nil)
        end.to raise_error ArgumentError
      end

      it "is passed a non-Hash object" do
        expect do
          cache.send(:write, [])
        end.to raise_error ArgumentError
      end
    end

    it "overwrites the existing cache" do
      File.open(path, "w") { |file| Marshal.dump({a: :a}, file) }
      old_sha = Digest::SHA1.hexdigest(path)
      expect(cache.send(:write, {b: :b})).to be_truthy
      new_sha = Digest::SHA1.hexdigest(path)

      expect(new_sha).not_to be old_sha
    end

    it "returns the hash argument" do
      hash = {a: :a}
      expect(cache.send(:write, hash)).to be(hash)
    end

    it "creates a new cache if one does not exist" do
      FileUtils.rm_rf(path)
      FileUtils.rm_rf(tmp_dir)
      expect(FileUtils).to receive(:mkdir_p).with(tmp_dir).and_call_original

      expect(cache.send(:write, {a: :a})).to be_truthy
      expect(File.exist?(path)).to be == true
    end
  end
end

