
describe Calabash::Cucumber::SimulatorLauncher do
  let(:base_dir) { File.join("tmp", "bundle-detection") }
  let(:a) { File.join(base_dir, "A.app") }
  let(:b) { File.join(base_dir, "B.app") }
  let(:c) { File.join(base_dir, "C.app") }
  let(:d) { File.join(base_dir, "D.app") }
  let(:launcher) { Calabash::Cucumber::SimulatorLauncher.new }

  before do
    base_dir = File.join("tmp", "bundle-detection")
    FileUtils.rm_rf(base_dir)
    FileUtils.mkdir_p(base_dir)

    make_bundle = lambda do |bundle_path|
      FileUtils.mkdir_p(bundle_path)
      name = File.basename(bundle_path).split(".")[0]
      FileUtils.touch(File.join(bundle_path, name))

      pbuddy = RunLoop::PlistBuddy.new
      info_plist = File.join(bundle_path, "Info.plist")
      pbuddy.create_plist(info_plist)
      bundle_id = "com.example.#{name}"
      pbuddy.plist_set("CFBundleIdentifier", "string", bundle_id, info_plist)
      pbuddy.plist_set("CFBundleExecutable", "string", name, info_plist)
    end

    make_bundle.call(a)
    make_bundle.call(b)
    make_bundle.call(c)
    make_bundle.call(d)
  end

  describe "#collect_app_bundles" do
    let(:app_a) { RunLoop::App.new(a) }
    let(:app_b) { RunLoop::App.new(b) }
    let(:app_c) { RunLoop::App.new(c) }
    let(:app_d) { RunLoop::App.new(d) }

    let(:lipo_a) { RunLoop::Lipo.new(a) }
    let(:lipo_b) { RunLoop::Lipo.new(b) }
    let(:lipo_c) { RunLoop::Lipo.new(c) }
    let(:lipo_d) { RunLoop::Lipo.new(d) }

    let(:v8) { RunLoop::Version.new("8.0") }
    let(:v6) { RunLoop::Version.new("6.0") }

    let(:i386) { ["i386"] }
    let(:x86_64) { ["x86_64"] }
    let(:fat) { i386 + x86_64 }

    before do
      allow(launcher).to receive(:app).with(a).and_return(app_a)
      allow(launcher).to receive(:app).with(b).and_return(app_b)
      allow(launcher).to receive(:app).with(c).and_return(app_c)
      allow(launcher).to receive(:app).with(d).and_return(app_d)

      allow(launcher).to receive(:lipo).with(a).and_return(lipo_a)
      allow(launcher).to receive(:lipo).with(b).and_return(lipo_b)
      allow(launcher).to receive(:lipo).with(c).and_return(lipo_c)
      allow(launcher).to receive(:lipo).with(d).and_return(lipo_d)
    end

    it "collects valid bundles" do
      expect(app_a).to receive(:calabash_server_version).and_return(v8)
      expect(app_b).to receive(:calabash_server_version).and_return(v8)
      expect(app_c).to receive(:calabash_server_version).and_return(v8)
      expect(app_d).to receive(:calabash_server_version).and_return(v8)

      expect(lipo_a).to receive(:info).and_return(fat)
      expect(lipo_b).to receive(:info).and_return(i386)
      expect(lipo_c).to receive(:info).and_return(x86_64)
      expect(lipo_d).to receive(:info).and_return(x86_64)

      actual = launcher.send(:collect_app_bundles, base_dir)
      expected = [a, b, c, d]
      expect(actual).to be == expected
    end

    it "rejects invalid bundles" do
      expect(RunLoop::App).to receive(:valid?).with(a).and_return false
      expect(RunLoop::App).to receive(:valid?).with(b).and_return false
      expect(RunLoop::App).to receive(:valid?).with(c).and_return false
      expect(RunLoop::App).to receive(:valid?).with(d).and_return false

      actual = launcher.send(:collect_app_bundles, base_dir)
      expect(actual).to be == []
    end

    it "rejects arm bundles" do
      expect(app_b).to receive(:calabash_server_version).and_return(v8)
      expect(app_c).to receive(:calabash_server_version).and_return(v8)

      expect(lipo_a).to receive(:info).and_return(["arm64"])
      expect(lipo_b).to receive(:info).and_return(i386)
      expect(lipo_c).to receive(:info).and_return(x86_64)
      expect(lipo_d).to receive(:info).and_return(["armv7"])

      actual = launcher.send(:collect_app_bundles, base_dir)
      expected = [b, c]
      expect(actual).to be == expected
    end

    it "rejects bundles without calabash server" do
      expect(app_a).to receive(:calabash_server_version).and_return(v8)
      expect(app_b).to receive(:calabash_server_version).and_return(nil)
      expect(app_c).to receive(:calabash_server_version).and_return(nil)
      expect(app_d).to receive(:calabash_server_version).and_return(v8)

      expect(lipo_a).to receive(:info).and_return(fat)
      expect(lipo_b).to receive(:info).and_return(i386)
      expect(lipo_c).to receive(:info).and_return(x86_64)
      expect(lipo_d).to receive(:info).and_return(x86_64)

      actual = launcher.send(:collect_app_bundles, base_dir)
      expected = [a, d]
      expect(actual).to be == expected
    end
  end

  describe "#select_most_recent_bundle" do
    it "returns nil if no bundles are collected" do
      expect(launcher).to receive(:collect_app_bundles).with(base_dir).and_return([])

      actual = launcher.send(:select_most_recent_bundle, base_dir)
      expect(actual).to be == nil
    end

    it "returns the most recently modified" do
      array = [a, b, c, d]
      expect(File).to receive(:mtime).with(a).at_least(:once).and_return(0)
      expect(File).to receive(:mtime).with(b).at_least(:once).and_return(1)
      expect(File).to receive(:mtime).with(c).at_least(:once).and_return(2)
      expect(File).to receive(:mtime).with(d).at_least(:once).and_return(3)

      expect(launcher).to receive(:collect_app_bundles).with(base_dir).and_return(array)

      actual = launcher.send(:select_most_recent_bundle, base_dir)
      expect(actual).to be == d
    end
  end
end

