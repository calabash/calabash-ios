describe Calabash::Cucumber::Launcher do

  let(:launcher) { Calabash::Cucumber::Launcher.new }
  let(:instruments) { RunLoop::Instruments.new }
  let(:simulator) { instruments.simulators.sample }

  describe "#reset_simulator" do
    it "default simulator" do
      stub_env({'DEVICE_TARGET' => nil})
      default = RunLoop::Core.default_simulator
      simulator = RunLoop::Device.device_with_identifier(default)

      actual = launcher.reset_simulator
      expect(actual.udid).to be == simulator.udid
    end

    it "can handle a RunLoop::Device" do
      actual = launcher.reset_simulator(simulator)
      expected = simulator.udid

      expect(actual.udid).to be == expected
    end
  end
end
