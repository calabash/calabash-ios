describe Calabash::Cucumber::Core do

  let(:actions) do
    Class.new do
      def swipe(dir, options); :success; end
    end.new
  end

  let(:launcher) do
    Class.new do
      def actions; ; end
    end.new
  end

  let(:world) do
    Class.new do
      include Calabash::Cucumber::Core
    end.new
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
          expect(world).to receive(:map).twice.and_return [true]
          expect(world).to receive(:assert_map_results).twice.and_return true
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
          expect(launcher).to receive(:actions).and_return actions
          expect(actions).to receive(:swipe).and_return :success
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
        expect(launcher).to receive(:actions).and_return actions
      end

      describe 'uia is not available' do
        it 'adds :status_bar_orientation' do
          options = {}
          merged = {:status_bar_orientation => :down}
          expect(actions).to receive(:swipe).with(:left, merged).and_return :success

          expect(world.swipe(:left, options)).to be == :success
        end

        # I don't understand why the :status_bar_orientation value is overwritten.
        it 'does overwrites :status_bar_orientation' do
          options = {:status_bar_orientation => :left}
          merged = {:status_bar_orientation => :down}

          expect(actions).to receive(:swipe).with(:left, merged).and_return :success

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
end

