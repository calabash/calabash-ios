require File.expand_path(File.join(__FILE__, '..', '..', 'spec_helper'))
describe 'calabash ios sim cli' do
  require File.expand_path(File.join(__FILE__, '..', '..', '..', 'bin', 'calabash-ios-sim'))

  it '#quit_sim' do
    sim_control = RunLoop::SimControl.new
    sim_control.launch_sim
    quit_sim
    expect(sim_control.sim_is_running?).to be == false
  end

  it '#calabash_sim_reset' do
    calabash_sim_reset
  end

  it '#calabash_sim_accessibility' do
    calabash_sim_accessibility
  end

  describe "#calabash_sim_locale" do
    it "prints a helpful message with no args" do
      actual = true
      out = capture_stdout do
        actual = calabash_sim_locale([])
      end.string

      expect(actual).to be_falsey
      expect(out[/Usage:/, 0]).to be_truthy
    end

    it "prints a helpful message with one arg" do
      actual = true
      out = capture_stdout do
        actual = calabash_sim_locale(["de"])
      end.string

      expect(actual).to be_falsey
      expect(out[/Usage:/, 0]).to be_truthy
    end

    it "fails when it cannot find DEVICE_TARGET" do
      allow(RunLoop::Environment).to receive(:device_target).and_return("Unknown Device")
      expect(RunLoop::Device).to receive(:detect_device).and_return(nil)

      actual = true
      out = capture_stdout do
        actual = calabash_sim_locale(["de", "de"])
      end.string

      expect(actual).to be_falsey
      expect(out[/DEVICE_TARGET/, 0]).to be_truthy
    end

    it "fails when default simulator cannot be found" do
      expect(RunLoop::Core).to receive(:default_simulator).and_return("iPhone 2s")
      expect(RunLoop::Device).to receive(:detect_device).and_return(nil)

      actual = true
      out = capture_stdout do
        actual = calabash_sim_locale(["de", "de"])
      end.string

      expect(actual).to be_falsey
      expect(out[/Could not find the default simulator/, 0]).to be_truthy
    end

    it "fails when passed a physical device target" do
      udid = "133688929205de7fb18d603c158ede219ae8dd1d"
      device = RunLoop::Device.new("denis", "8.0", udid)

      expect(RunLoop::Device).to receive(:detect_device).and_return(device)

      actual = true
      out = capture_stdout do
        actual = calabash_sim_locale(["de", "de"])
      end.string
      expect(actual).to be_falsey
      expect(out[/This tool is for simulators only/, 0]).to be_truthy
    end

    it "sets the local and language for default simulator" do
      actual = false

      out = capture_stdout do
        actual = calabash_sim_locale(["de", "de"])
      end.string

      expect(out[/-AppleLanguages/]).to be_truthy
      expect(out[/-AppleLocale/]).to be_truthy
      expect(out[/SUCCESS/]).to be_truthy
      expect(actual).to be_truthy
    end
  end
end
