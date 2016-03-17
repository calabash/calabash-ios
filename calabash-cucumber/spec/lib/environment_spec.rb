
describe Calabash::Cucumber::Environment do

  describe ".device_target" do

    describe "DEVICE_TARGET is defined" do
      it "simulator" do
        expect(RunLoop::Environment).to receive(:device_target).and_return("simulator")
        expect(RunLoop::Core).to receive(:default_simulator).and_return("Default Simulator")

        actual = Calabash::Cucumber::Environment.device_target
        expect(actual).to be == "Default Simulator"
      end

      it "device" do
        expect(RunLoop::Environment).to receive(:device_target).and_return("device")
        expect(RunLoop::Core).to receive(:detect_connected_device).and_return("a udid")

        actual = Calabash::Cucumber::Environment.device_target
        expect(actual).to be == "a udid"
      end

      it "anything else" do
        expect(RunLoop::Environment).to receive(:device_target).and_return("a")
        expect(Calabash::Cucumber::Environment.device_target).to be == "a"
      end
    end

    it "DEVICE_TARGET is not defined" do
      expect(RunLoop::Environment).to receive(:device_target).and_return(nil)
      expect(RunLoop::Core).to receive(:default_simulator).and_return("Default Simulator")

      actual = Calabash::Cucumber::Environment.device_target
      expect(actual).to be == "Default Simulator"
    end
  end
end
