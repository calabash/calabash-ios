
describe Calabash::Cucumber::Environment do

  describe ".device_target" do
    describe "returns nil" do
      it "DEVICE_TARGET is not defined" do
        stub_env({"DEVICE_TARGET" => nil})

        expect(Calabash::Cucumber::Environment.device_target).to be_falsey
      end

      it "DEVICE_TARGET is the empty string" do
        stub_env({"DEVICE_TARGET" => ""})

        expect(Calabash::Cucumber::Environment.device_target).to be_falsey
      end
    end

    it "returns the value of DEVICE_TARGET" do
      stub_env({"DEVICE_TARGET" => "anything"})

      expect(Calabash::Cucumber::Environment.device_target).to be == "anything"
    end
  end
end
