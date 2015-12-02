describe Calabash::Cucumber::UsageTracker do

  let(:tracker) { Calabash::Cucumber::UsageTracker.new }

  it "#host_os" do
    host_os = tracker.send(:host_os)
    expect(tracker.instance_variable_get(:@host_os)).to be == host_os
  end

  it "#host_os_version" do
    version = tracker.send(:host_os_version)
    expect(tracker.instance_variable_get(:@host_os_version)).to be == version
  end

  it "#info" do
    info = tracker.send(:info)
    expect(info[:event_name]).to be == "session"
  end
end

