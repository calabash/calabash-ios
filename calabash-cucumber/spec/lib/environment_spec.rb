
describe Calabash::Cucumber::Environment do

  describe ".xcode" do
    it "XTC returns nil" do
      expect(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(true)

      expect(Calabash::Cucumber::Environment.xcode).to be == nil
    end

    it "set class variable" do
      expect(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(false)

      actual = Calabash::Cucumber::Environment.xcode
      expect(actual).to be_a_kind_of(RunLoop::Xcode)
      expect(Calabash::Cucumber::Environment.class_variable_get(:@@xcode)).to be == actual
    end
  end

  describe ".simctl" do
    it "XTC returns nil" do
      expect(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(true)

      expect(Calabash::Cucumber::Environment.simctl).to be == nil
    end

    it "set class variable" do
      expect(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(false)

      actual = Calabash::Cucumber::Environment.simctl
      expect(actual).to be_a_kind_of(RunLoop::SimControl)
      expect(Calabash::Cucumber::Environment.class_variable_get(:@@simctl)).to be == actual
    end
  end

  describe ".instruments" do
    it "XTC returns nil" do
      expect(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(true)

      expect(Calabash::Cucumber::Environment.instruments).to be == nil
    end

    it "set class variable" do
      expect(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(false)

      actual = Calabash::Cucumber::Environment.instruments
      expect(actual).to be_a_kind_of(RunLoop::Instruments)
      expect(Calabash::Cucumber::Environment.class_variable_get(:@@instruments)).to be == actual
    end
  end

  it ".xtc?" do
    expect(RunLoop::Environment).to receive(:xtc?).and_return(true)
    expect(Calabash::Cucumber::Environment.xtc?).to be_truthy

    expect(RunLoop::Environment).to receive(:xtc?).and_return(false)
    expect(Calabash::Cucumber::Environment.xtc?).to be_falsey
  end

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

  describe ".device_endpoint" do
    it "DEVICE_ENDPOINT is defined" do
      expect(RunLoop::Environment).to receive(:device_endpoint).and_return("endpoint")

      actual = Calabash::Cucumber::Environment.device_endpoint
      expect(actual).to be == "endpoint"
    end

    it "DEVICE_ENDPOINT is not defined" do
      expect(RunLoop::Environment).to receive(:device_endpoint).and_return(nil)

      actual = Calabash::Cucumber::Environment.device_endpoint
      expect(actual).to be == Calabash::Cucumber::Environment::DEFAULT_AUT_ENDPOINT
    end
  end
end
