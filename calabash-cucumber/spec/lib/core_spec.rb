describe Calabash::Cucumber::Core do

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
  end

  let(:gesture_performer) do
    Class.new do
      def swipe(_, _); :success; end
      def to_s; "#<GesturePerformer Interface>"; end
      def inspect; to_s; end
    end.new
  end

  let(:launcher) do
    Class.new do
      def gesture_performer; ; end
      def run_loop; ; end
      def instruments?; ; end
      def to_s; "#<Launcher>"; end
      def inspect; to_s; end
    end.new
  end

  let(:world) do
    Class.new do
      include Calabash::Cucumber::Core
      def to_s; "#<World>"; end
      def inspect; to_s; end
    end.new
  end

  describe "logging" do
    it "#calabash_warn" do
      actual = capture_stdout do
        world.calabash_warn("You have been warned")
      end.string.gsub(/\e\[(\d+)m/, "")

      expect(actual).to be == "WARN: You have been warned\n"
    end

    it "#calabash_info" do
      actual = capture_stdout do
        world.calabash_info("You have been info'd")
      end.string.gsub(/\e\[(\d+)m/, "").strip

      # The .strip above future proofs against changes to the silly leading
      # space in RunLoop.log_info2.
      expect(actual).to be == "INFO: You have been info'd"
    end

    it "#deprecated" do
      version = '0.9.169'
      dep_msg = 'this is a deprecation message'
      out = capture_stdout do
        world.deprecated(version, dep_msg, :warn)
      end.string.gsub(/\e\[(\d+)m/, "")

      tokens = out.split($-0)
      message = tokens[0]
      expect(message).to be == "WARN: deprecated '#{version}' - #{dep_msg}"
      expect(tokens.count).to be > 5
      expect(tokens.count).to be < 9
    end
  end

  describe '#scroll' do
    describe 'handling direction argument' do
      describe 'raises error if invalid' do
        it 'keywords' do
          expect do
            world.scroll("query", :sideways)
          end.to raise_error ArgumentError
        end

        it 'strings' do
          expect do
            world.scroll("query", 'diagonal')
          end.to raise_error ArgumentError
        end
      end

      describe 'valid' do
        before do
          expect(Calabash::Cucumber::Map).to receive(:map).twice.and_return [true]
          expect(Calabash::Cucumber::Map).to receive(:assert_map_results).twice.and_return true
        end

        it 'up' do
          expect(world.scroll('', 'up')).to be_truthy
          expect(world.scroll('', :up)).to be_truthy
        end

        it 'down' do
          expect(world.scroll('', 'down')).to be_truthy
          expect(world.scroll('', :down)).to be_truthy
        end

        it 'left' do
          expect(world.scroll('', 'left')).to be_truthy
          expect(world.scroll('', :left)).to be_truthy
        end

        it 'right' do
          expect(world.scroll('', 'right')).to be_truthy
          expect(world.scroll('', :right)).to be_truthy
        end
      end
    end
  end

  describe '#swipe' do
    describe 'handling :force options' do

      describe 'valid options' do

        before do
          expect(world).to receive(:uia_available?).and_return true
          expect(world).to receive(:launcher).and_return launcher
          expect(launcher).to receive(:gesture_performer).and_return gesture_performer
          expect(gesture_performer).to receive(:swipe).and_return :success
        end

        it ':light' do
          expect(world.swipe(:left, {:force => :light})).to be == :success
        end

        it ':normal' do
          expect(world.swipe(:left, {:force => :light})).to be == :success
        end

        it ':strong' do
          expect(world.swipe(:left, {:force => :light})).to be == :success
        end
      end

      it 'raises error if unknown :force is passed' do
        expect(world).to receive(:uia_available?).and_return true
        expect {
          world.swipe(:left, {:force => :unknown})
        }.to raise_error ArgumentError
      end
    end

    describe 'handling options' do

      before do
        expect(world).to receive(:uia_available?).and_return false
        expect(world).to receive(:status_bar_orientation).and_return :down
        expect(world).to receive(:launcher).and_return launcher
        expect(launcher).to receive(:gesture_performer).and_return gesture_performer
      end

      describe 'uia is not available' do
        it 'adds :status_bar_orientation' do
          options = {}
          merged = {:status_bar_orientation => :down}
          expect(gesture_performer).to receive(:swipe).with(:left, merged).and_return :success

          expect(world.swipe(:left, options)).to be == :success
        end

        # I don't understand why the :status_bar_orientation value is overwritten.
        it 'does overwrites :status_bar_orientation' do
          options = {:status_bar_orientation => :left}
          merged = {:status_bar_orientation => :down}

          expect(gesture_performer).to receive(:swipe).with(:left, merged).and_return :success

          expect(world.swipe(:left, options)).to be == :success
        end
      end
    end
  end

  describe "#backdoor" do
    let(:args) do
      {
        :method => :post,
        :path => "backdoor"
      }
    end

    let(:selector) { "myBackdoor:" }
    let(:parameters) do
      {
        :selector => selector,
        :arguments => ["a", "b", "c"]
      }
    end

    describe "raises errors" do
      it "http call fails" do
        class MyHTTPError < RuntimeError ; end
        expect(world).to receive(:http).and_raise MyHTTPError, "My error"

        expect do
          world.backdoor(selector)
        end.to raise_error RuntimeError, /My error/
      end

      it "parsing the response fails" do
        expect(world).to receive(:http).and_return ""
        class MyJSONError < RuntimeError ; end
        expect(world).to receive(:response_body_to_hash).with("").and_raise MyJSONError, "JSON error"

        expect do
          world.backdoor(selector)
        end.to raise_error RuntimeError, /JSON error/
      end

      it "outcome is FAILURE" do
        hash = {
          "outcome" => "FAILURE",
          "reason" => "This is unreasonable",
          "details" => "The sordid details"
        }

        expect(world).to receive(:http).and_return ""
        expect(world).to receive(:response_body_to_hash).with("").and_return(hash)

        expect do
          world.backdoor(selector, "a", "b", "c")
        end.to raise_error RuntimeError, /backdoor call failed/
      end
    end

    it "returns the results key" do
        hash = {
          "outcome" => "SUCCESS",
          "results" => 1
        }

      expect(world).to receive(:http).with(args, parameters).and_return ""
      expect(world).to receive(:response_body_to_hash).with("").and_return hash

      actual = world.backdoor(selector, "a", "b", "c")
      expect(actual).to be == hash["results"]
    end
  end

  describe "send_app_to_background" do
    describe "raises errors" do

      it "raises argument error when seconds < 1.0" do
        expect do
          world.send_app_to_background(0.5)
        end.to raise_error ArgumentError, /must be >= 1.0/
      end

      it "http call fails" do
        class MyHTTPError < RuntimeError ; end
        expect(world).to receive(:http).and_raise MyHTTPError, "My error"

        expect do
          world.send_app_to_background(1.0)
        end.to raise_error RuntimeError, /My error/
      end

      it "parsing the response fails" do
        expect(world).to receive(:http).and_return ""
        class MyJSONError < RuntimeError ; end
        expect(world).to receive(:response_body_to_hash).with("").and_raise MyJSONError, "JSON error"

        expect do
          world.send_app_to_background(1.0)
        end.to raise_error RuntimeError, /JSON error/
      end

      it "outcome is FAILURE" do
        hash = {
          "outcome" => "FAILURE",
          "reason" => "This is unreasonable",
          "details" => "The sordid details"
        }

        expect(world).to receive(:http).and_return ""
        expect(world).to receive(:response_body_to_hash).with("").and_return(hash)

        expect do
          world.send_app_to_background(1.0)
        end.to raise_error RuntimeError, /Could not send app to background:/
      end
    end

    let(:args) { {:method => :post, :path => "suspend"} }
    let(:parameters) { {:duration => 1.0 } }

    it "sets the http parameters correctly" do
      parameters[:duration] = 5.0

      hash = {
        "outcome" => "SUCCESS",
        "results" => 1
      }

      expect(world).to receive(:http).with(args, parameters).and_return ""
      expect(world).to receive(:response_body_to_hash).with("").and_return(hash)

      actual = world.send_app_to_background(5.0)
      expect(actual).to be == hash["results"]
    end

    it "returns the results key" do

      hash = {
        "outcome" => "SUCCESS",
        "results" => 1
      }

      expect(world).to receive(:http).with(args, parameters).and_return ""
      expect(world).to receive(:response_body_to_hash).with("").and_return hash

      actual = world.send_app_to_background(1.0)
      expect(actual).to be == hash["results"]
    end
  end

  describe "console_attach" do
    it "raises an error on the XTC" do
      expect(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(true)

      expect do
        world.console_attach
      end.to raise_error RuntimeError,
      /This method is not available on the Xamarin Test Cloud/
    end

    it "calls launcher#attach" do
      launcher = Calabash::Cucumber::Launcher.new
      strategy = :host
      options = { :uia_strategy => strategy }
      expect(launcher).to receive(:attach).with(options).and_return(launcher)
      expect(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(false)

      actual = world.console_attach(strategy)
      expect(actual).to be == launcher
    end
  end

  describe "shake" do
    describe "raises errors" do

      it "raises argument error when seconds < 0.0" do
        expect do
          world.shake(0.0)
        end.to raise_error ArgumentError, /must be >= 0.0/
      end

      it "http call fails" do
        class MyHTTPError < RuntimeError ; end
        expect(world).to receive(:http).and_raise MyHTTPError, "My error"

        expect do
          world.shake(1.0)
        end.to raise_error RuntimeError, /My error/
      end

      it "parsing the response fails" do
        expect(world).to receive(:http).and_return ""
        class MyJSONError < RuntimeError ; end
        expect(world).to receive(:response_body_to_hash).with("").and_raise MyJSONError, "JSON error"

        expect do
          world.shake(1.0)
        end.to raise_error RuntimeError, /JSON error/
      end

      it "outcome is FAILURE" do
        hash = {
          "outcome" => "FAILURE",
          "reason" => "This is unreasonable",
          "details" => "The sordid details"
        }

        expect(world).to receive(:http).and_return ""
        expect(world).to receive(:response_body_to_hash).with("").and_return(hash)

        expect do
          world.shake(1.0)
        end.to raise_error RuntimeError, /Could not shake the device/
      end
    end

    let(:args) { {:method => :post, :path => "shake"} }
    let(:parameters) { {:duration => 1.0 } }

    it "sets the http parameters correctly" do
      parameters[:duration] = 5.0

      hash = {
        "outcome" => "SUCCESS",
        "results" => 1
      }

      expect(world).to receive(:http).with(args, parameters).and_return ""
      expect(world).to receive(:response_body_to_hash).with("").and_return(hash)

      actual = world.shake(5.0)
      expect(actual).to be == hash["results"]
    end

    it "returns the results key" do

      hash = {
        "outcome" => "SUCCESS",
        "results" => 1
      }

      expect(world).to receive(:http).with(args, parameters).and_return ""
      expect(world).to receive(:response_body_to_hash).with("").and_return hash

      actual = world.shake(1.0)
      expect(actual).to be == hash["results"]
    end
  end

  context "#launcher" do
    it "returns @@launcher" do
      expect(Calabash::Cucumber::Launcher).to receive(:launcher).and_return(launcher)

      expect(world.launcher).to be == launcher
    end

    it "returns nil" do
      expect(Calabash::Cucumber::Launcher).to receive(:launcher).and_return(nil)

      expect(world.launcher).to be == nil
    end
  end

  context "#run_loop" do
    it "returns hash representing a run_loop if one is available" do
      expect(Calabash::Cucumber::Launcher).to receive(:launcher_if_used).and_return(launcher)
      expect(launcher).to receive(:run_loop).and_return({})

      expect(world.run_loop).to be == {}
    end

    it "returns nil if Launcher::@@launcher is nil" do
      expect(Calabash::Cucumber::Launcher).to receive(:launcher_if_used).and_return(nil)

      expect(world.run_loop).to be == nil
    end

    it "returns nil if @@launcher.run_loop is nil" do
      expect(Calabash::Cucumber::Launcher).to receive(:launcher_if_used).and_return(launcher)
      expect(launcher).to receive(:run_loop).and_return(nil)

      expect(world.run_loop).to be == nil
    end
  end

  context "#tail_run_loop_log" do
    let(:path) { "path/to/log.txt" }
    let(:hash) { {:log_file => path} }

    it "raises error if there is not an active run-loop" do
      expect(world).to receive(:run_loop).and_return(nil)

      expect do
        world.tail_run_loop_log
      end.to raise_error RuntimeError,
                         /Unable to tail instruments log because there is no active run-loop/
    end

    it "raises error if there is active run-loop but it is not :instruments based" do
      expect(world).to receive(:run_loop).and_return(hash)
      expect(world).to receive(:launcher).and_return(launcher)
      expect(launcher).to receive(:instruments?).and_return(false)

      expect do
        world.tail_run_loop_log
      end.to raise_error RuntimeError, /Cannot tail a non-instruments run-loop/
    end

    it "opens a Terminal window to tail run-loop log file" do
      expect(world).to receive(:run_loop).at_least(:once).and_return(hash)
      expect(world).to receive(:launcher).and_return(launcher)
      expect(launcher).to receive(:instruments?).and_return(true)
      expect(Calabash::Cucumber::LogTailer).to receive(:tail_in_terminal).with(path).and_return(true)

      expect(world.tail_run_loop_log).to be_truthy
    end
  end

  context "#dump_run_loop_log" do
    let(:path) { File.join(Resources.shared.resources_dir, "run_loop.out") }
    let(:hash) { {:log_file => path} }

    it "raises error if there is not an active run-loop" do
      expect(world).to receive(:run_loop).and_return(nil)

      expect do
        world.dump_run_loop_log
      end.to raise_error RuntimeError,
                         /Unable to dump run-loop log because there is no active run-loop/
    end

    it "raises error if there is an active run-loop but it is not :instruments based" do
      expect(world).to receive(:run_loop).and_return(hash)
      expect(world).to receive(:launcher).and_return(launcher)
      expect(launcher).to receive(:instruments?).and_return(false)

      expect do
        world.dump_run_loop_log
      end.to raise_error RuntimeError, /Cannot dump non-instruments run-loop/
    end

    it "prints the contents of the run-loop log file" do
      expect(world).to receive(:run_loop).at_least(:once).and_return(hash)
      expect(world).to receive(:launcher).and_return(launcher)
      expect(launcher).to receive(:instruments?).and_return(true)

      expect(world.dump_run_loop_log).to be_truthy
    end
  end
end
