describe Calabash::Cucumber::UsageTracker do

  let(:tracker) { Calabash::Cucumber::UsageTracker.new }

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

