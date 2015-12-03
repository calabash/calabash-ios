describe Calabash::Cucumber::UsageTracker do

  let(:tracker) { Calabash::Cucumber::UsageTracker.new }

  describe "@@track_usage" do
    before do
      Calabash::Cucumber::UsageTracker.class_variable_set(:@@track_usage, nil)
      allow(Calabash::Cucumber::UsageTracker).to receive(:xtc?).and_return false
    end

    it ".enable_usage_tracking" do
      expect(Calabash::Cucumber::UsageTracker.enable_usage_tracking).to be_truthy
      expect(Calabash::Cucumber::UsageTracker.send(:track_usage?)).to be_truthy
    end

    it ".disable_usage_tracking" do
      expect(Calabash::Cucumber::UsageTracker.disable_usage_tracking).to be_falsey
      expect(Calabash::Cucumber::UsageTracker.send(:track_usage?)).to be_falsey
    end
  end

  describe ".xtc?" do
    it "truthy" do
      stub_env({"XAMARIN_TEST_CLOUD" => "1"})
      expect(Calabash::Cucumber::UsageTracker.send(:xtc?)).to be_truthy
    end

    it "falsey" do
      stub_env({"XAMARIN_TEST_CLOUD" => "0"})
      expect(Calabash::Cucumber::UsageTracker.send(:xtc?)).to be_falsey
    end
  end

  it "#post_usage" do
    expect(HTTPClient).not_to receive(:post)
    expect(Calabash::Cucumber::UsageTracker).to receive(:track_usage?).and_return false

    tracker.post_usage
  end

  it "#host_os" do
    host_os = tracker.send(:host_os)
    expect(host_os).to be_truthy
    expect(tracker.instance_variable_get(:@host_os)).to be == host_os
  end

  it "#host_os_version" do
    version = tracker.send(:host_os_version)
    expect(version).to be_truthy
    expect(tracker.instance_variable_get(:@host_os_version)).to be == version
  end

  it "#info" do
    info = tracker.send(:info)
    expect(info[:event_name]).to be == "session"
  end

  it "#irb?" do
    expect(tracker.send(:irb?)).to be_falsey
  end

  it "#ruby_version" do
    expect(tracker.send(:ruby_version)).to be_truthy
  end

  it "#used_bundle_exec?" do
    tracker.send(:used_bundle_exec?)
  end

  it "#used_cucumber?" do
    expect(tracker.send(:used_cucumber?)).to be_falsey
  end
end

