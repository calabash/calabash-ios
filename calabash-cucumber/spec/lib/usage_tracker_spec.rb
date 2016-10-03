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
  end

  it "#user_id" do
    prefs = Calabash::Cucumber::Preferences.new
    expect(tracker).to receive(:preferences).and_return prefs
    expect(prefs).to receive(:distinct_id).and_return "distinct id"

    expect(tracker.send(:distinct_id)).to be == "distinct id"
  end

  it "#info_we_are_allowed_to_track" do
    prefs = Calabash::Cucumber::Preferences.new
    expect(tracker).to receive(:preferences).and_return prefs
    expect(prefs).to receive(:usage_tracking).and_return "allowed"

    expect(tracker.send(:info_we_are_allowed_to_track)).to be == "allowed"
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
      expect(tracker).to receive(:info_we_are_allowed_to_track).and_return "anything but 'none'"
      tracker.post_usage
    end

    it "logs to calabash.log when error is raised" do
      expect(HTTPClient).to receive(:post).and_raise StandardError
      expect(tracker).to receive(:info).and_return({})
      expect(tracker).to receive(:info_we_are_allowed_to_track).and_return "anything but 'none'"
      expect(Calabash::Cucumber::UsageTracker).to receive(:track_usage?).and_return true

      expect(Calabash::Cucumber).to receive(:timestamp).and_return("stamp")
      tracker.post_usage
      log_file = Calabash::Cucumber.send(:calabash_log_file)

      lines = File.read(log_file).force_encoding("utf-8").split($-0).reverse
      expect(lines[0]).to be == "stamp StandardError"
      expect(lines[1]).to be == "stamp ERROR: Could not post usage tracking information:"
    end

    describe "does not post" do
      it "track_usage? is false" do
        expect(HTTPClient).not_to receive(:post)
        expect(Calabash::Cucumber::UsageTracker).to receive(:track_usage?).and_return false
        expect(tracker).not_to receive(:info_we_are_allowed_to_track)
        tracker.post_usage
      end

      it "allowed_to_track == none" do
        expect(HTTPClient).not_to receive(:post)
        expect(Calabash::Cucumber::UsageTracker).to receive(:track_usage?).and_return true
        expect(tracker).to receive(:info_we_are_allowed_to_track).and_return "none"
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
      expect(tracker).to receive(:info_we_are_allowed_to_track).and_return "none"

      expect do
        tracker.send(:info)
      end.to raise_error RuntimeError,
      /This method should not be called if the user does not want to be tracked/
    end

    it "returns only events if allowed == events" do
      expect(tracker).to receive(:info_we_are_allowed_to_track).and_return "events"
      expect(tracker).to receive(:distinct_id).and_return "distinct id"

      hash = tracker.send(:info)
      expect(hash.count).to be == 3
      expect(hash[:event_name]).to be == "session"
      expect(hash[:data_version]).to be_truthy
      expect(hash[:distinct_id]).to be == "distinct id"
    end

    it "returns events and system info if allowed == system_info" do
      expect(tracker).to receive(:info_we_are_allowed_to_track).and_return "system_info"
      expect(tracker).to receive(:distinct_id).and_return "distinct id"

      hash = tracker.send(:info)

      expect(hash.count).to be == 17
      expect(hash[:event_name]).to be == "session"
      expect(hash[:data_version]).to be_truthy
      expect(hash[:distinct_id]).to be == "distinct id"

      expect(hash[:platform]).to be == "iOS"
      expect(hash[:host_os]).to be_truthy
      expect(hash[:host_os_version]).to be_truthy
      expect(hash[:irb]).to be == false
      expect(hash[:ruby_version]).to be_truthy
      expect(hash.has_key?(:used_bundle_exec)).to be_truthy
      expect(hash[:used_cucumber]).to be == false
      expect(hash[:version]).to be_truthy
      expect(hash.has_key?(:ci)).to be == true
      expect(hash.has_key?(:jenkins)).to be == true
      expect(hash.has_key?(:travis)).to be == true
      expect(hash.has_key?(:circle_ci)).to be == true
      expect(hash.has_key?(:teamcity)).to be == true
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

