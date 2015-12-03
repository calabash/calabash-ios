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

  it "#preferences" do
    prefs = tracker.send(:preferences)
    expect(prefs).to be_a_kind_of(Calabash::Cucumber::Preferences)
    expect(prefs).to be == tracker.send(:preferences)
    expect(tracker.instance_variable_get(:@preferences)).to be == prefs
  end

  it "#user_id" do
    prefs = Calabash::Cucumber::Preferences.new
    expect(tracker).to receive(:preferences).and_return prefs
    expect(prefs).to receive(:user_id).and_return "user id"

    expect(tracker.send(:user_id)).to be == "user id"
    expect(tracker.instance_variable_get(:@user_id)).to be == "user id"
  end

  it "#allowed_to_track" do
    prefs = Calabash::Cucumber::Preferences.new
    expect(tracker).to receive(:preferences).and_return prefs
    expect(prefs).to receive(:usage_tracking).and_return "allowed"

    expect(tracker.send(:allowed_to_track)).to be == "allowed"
    expect(tracker.instance_variable_get(:@allowed_to_track)).to be == "allowed"
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

  describe "#post_usage" do

    it "posts" do
      expect(tracker).to receive(:info).and_return({})
      expect(HTTPClient).to receive(:post)
      expect(Calabash::Cucumber::UsageTracker).to receive(:track_usage?).and_return true
      expect(tracker).to receive(:allowed_to_track).and_return "anything by 'none'"
      tracker.post_usage
    end

    describe "does not post" do
      it "track_usage? is false" do
        expect(HTTPClient).not_to receive(:post)
        expect(Calabash::Cucumber::UsageTracker).to receive(:track_usage?).and_return false
        expect(tracker).not_to receive(:allowed_to_track)
        tracker.post_usage
      end

      it "allowed_to_track == none" do
        expect(HTTPClient).not_to receive(:post)
        expect(Calabash::Cucumber::UsageTracker).to receive(:track_usage?).and_return true
        expect(tracker).to receive(:allowed_to_track).and_return "none"
        tracker.post_usage
      end
    end
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

  describe "#info" do
    it "returns {} if allowed is none" do
      expect(tracker).to receive(:allowed_to_track).and_return "none"

      expect(tracker.send(:info)).to be == {}
    end

    it "returns only events if allowed == events" do
      expect(tracker).to receive(:allowed_to_track).and_return "events"
      expect(tracker).to receive(:user_id).and_return "user id"

      hash = tracker.send(:info)
      expect(hash.count).to be == 3
      expect(hash[:event_name]).to be == "session"
      expect(hash[:data_version]).to be_truthy
      expect(hash[:user_id]).to be == "user id"
    end

    it "returns events and system info if allowed == system_info" do
      expect(tracker).to receive(:allowed_to_track).and_return "system_info"
      expect(tracker).to receive(:user_id).and_return "user id"

      hash = tracker.send(:info)

      expect(hash.count).to be == 16
      expect(hash[:event_name]).to be == "session"
      expect(hash[:data_version]).to be_truthy
      expect(hash[:user_id]).to be == "user id"

      expect(hash[:platform]).to be == "iOS"
      expect(hash[:host_os]).to be_truthy
      expect(hash[:host_os_version]).to be_truthy
      expect(hash[:irb]).to be == false
      expect(hash[:ruby_version]).to be_truthy
      expect(hash.has_key?(:used_bundle_exec)).to be_truthy
      expect(hash[:used_cucumber]).to be == false
      expect(hash[:version]).to be_truthy
      expect(hash.has_key?(:ci)).to be_truthy
      expect(hash.has_key?(:jenkins)).to be_truthy
      expect(hash.has_key?(:travis)).to be_truthy
      expect(hash.has_key?(:circle_ci)).to be_truthy
      expect(hash.has_key?(:teamcity)).to be_truthy
    end
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

