
describe Calabash::Cucumber::Environment do

  let(:defaults) { Calabash::Cucumber::Environment::DEFAULTS }

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
      expect(actual).to be == defaults[:aut_endpoint]
    end
  end

  describe ".http_connection_retries" do
    it "respects MAX_CONNECT_RETRIES" do
      stub_env({"MAX_CONNECT_RETRIES" => 5})

      actual = Calabash::Cucumber::Environment.http_connection_retries
      expect(actual).to be == 5
    end

    it "fails back to the defaults" do
      stub_env({"MAX_CONNECT_RETRIES" => nil})
      actual = Calabash::Cucumber::Environment.http_connection_retries
      expect(actual).to be == defaults[:http_connection_retries]

      stub_env({"MAX_CONNECT_RETRIES" => ""})
      actual = Calabash::Cucumber::Environment.http_connection_retries
      expect(actual).to be == defaults[:http_connection_retries]
    end
  end

  describe ".http_connection_timeout" do
    it "respects CONNECTION_TIMEOUT" do
      stub_env({"CONNECTION_TIMEOUT" => 5})

      actual = Calabash::Cucumber::Environment.http_connection_timeout
      expect(actual).to be == 5
    end

    it "falls back to defaults" do
      stub_env({"CONNECTION_TIMEOUT" => nil})
      actual = Calabash::Cucumber::Environment.http_connection_timeout
      expect(actual).to be == defaults[:http_connection_timeout]

      stub_env({"CONNECTION_TIMEOUT" => ""})
      actual = Calabash::Cucumber::Environment.http_connection_timeout
      expect(actual).to be == defaults[:http_connection_timeout]
    end
  end

  describe ".reset_between_scenarios?" do
    it "returns true" do
      stub_env({"RESET_BETWEEN_SCENARIOS" => "1"})

      expect(Calabash::Cucumber::Environment.reset_between_scenarios?).to be_truthy
    end

    it "returns false" do
      stub_env({"RESET_BETWEEN_SCENARIOS" => nil})
      expect(Calabash::Cucumber::Environment.reset_between_scenarios?).to be_falsey

      stub_env({"RESET_BETWEEN_SCENARIOS" => 1})
      expect(Calabash::Cucumber::Environment.reset_between_scenarios?).to be_falsey
    end
  end

  describe ".run_loop_device" do
    let(:identifier) { "some device id" }

    before do
      allow(Calabash::Cucumber::Environment).to receive(:device_target).and_return(identifier)
    end

    it "returns nil on the XTC" do
      expect(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(true)

      actual = Calabash::Cucumber::Environment.run_loop_device
      expect(actual).to be == nil
    end

    it "returns a RunLoop::Device instance" do
      allow(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(false)
      options = {
        :sim_control => Calabash::Cucumber::Environment.simctl,
        :instruments => Calabash::Cucumber::Environment.instruments
      }
      expect(RunLoop::Device).to receive(:device_with_identifier).with(identifier, options).and_return(:device)


      actual = Calabash::Cucumber::Environment.run_loop_device
      expect(actual).to be == :device
    end
  end

  describe "Quitting the app after each Scenario" do
    describe ".quit_app_after_scenario?" do
      it "QUIT_APP_AFTER_SCENARIO=0" do
        stub_env({"QUIT_APP_AFTER_SCENARIO" => "0"})

        expect(Calabash::Cucumber::Environment.quit_app_after_scenario?).to be_falsey
      end

      it "QUIT_APP_AFTER_SCENARIO=1" do
        stub_env({"QUIT_APP_AFTER_SCENARIO" => "1"})

        expect(Calabash::Cucumber::Environment.quit_app_after_scenario?).to be_truthy
      end

      describe "QUIT_APP_AFTER_SCENARIO vs NO_STOP" do
        before do
          stub_env({"QUIT_APP_AFTER_SCENARIO" => nil})
        end

        it "NO_STOP=1" do
          stub_env({"NO_STOP" => "1"})

          expect(Calabash::Cucumber::Environment.quit_app_after_scenario?).to be_falsey
        end

        it "NO_STOP=0" do
          stub_env({"NO_STOP" => "0"})

          expect(Calabash::Cucumber::Environment.quit_app_after_scenario?).to be_truthy
        end

        it "NO_STOP is undefined" do
          stub_env({"NO_STOP" => ""})
          expect(Calabash::Cucumber::Environment.quit_app_after_scenario?).to be_truthy

          stub_env({"NO_STOP" => nil})
          expect(Calabash::Cucumber::Environment.quit_app_after_scenario?).to be_truthy
        end
      end
    end
    describe ".no_stop?" do
      describe "NO_STOP is defined" do
        it "is 1" do
          stub_env({"NO_STOP" => "1"})
          expect(RunLoop).to receive(:deprecated).and_call_original

          expect(Calabash::Cucumber::Environment.send(:no_stop?)).to be_truthy
        end

        it "is not 1" do
          stub_env({"NO_STOP" => "0"})
          expect(RunLoop).to receive(:deprecated).and_call_original

          expect(Calabash::Cucumber::Environment.send(:no_stop?)).to be_falsey
        end
      end

      it "NO_STOP is undefined" do
        stub_env({"NO_STOP" => nil})
        expect(RunLoop).not_to receive(:deprecated)

        expect(Calabash::Cucumber::Environment.send(:no_stop?)).to be_falsey
      end
    end
  end
end
