
describe Calabash::Cucumber::Gestures::Instruments do

  context ".name" do
    it "returns :instruments" do
      expect(Calabash::Cucumber::Gestures::Instruments.name).to be == :instruments
    end
  end

  context ".expect_valid_init_args" do
    context "raises errors when" do
      it "is passed nil" do
        expect do
          Calabash::Cucumber::Gestures::Instruments.expect_valid_init_args(nil)
        end.to raise_error ArgumentError, /Expected non-nil argument for initializer/
      end

      it "is not passed an array" do
        expect do
          Calabash::Cucumber::Gestures::Instruments.expect_valid_init_args({})
        end.to raise_error ArgumentError, /Expected an array argument for initializer/
      end

      it "is passes an array with nil first element" do
        expect do
          Calabash::Cucumber::Gestures::Instruments.expect_valid_init_args([])
        end.to raise_error ArgumentError, /Expected first element of args to be non-nil/
      end

      it "is passes an array with more than one argument" do
        expect do
          Calabash::Cucumber::Gestures::Instruments.expect_valid_init_args(["a", "b"])
        end.to raise_error ArgumentError,
                           /Expected args to have exactly one element but found:/
      end
    end

    it "calls .expect_valid_run_loop if valid first arg" do
      hash = {}
      args = [hash]
      expect(Calabash::Cucumber::Gestures::Instruments).to receive(:expect_valid_run_loop).with(hash).and_return :valid

      actual = Calabash::Cucumber::Gestures::Instruments.expect_valid_init_args(args)
      expect(actual).to be == :valid
    end
  end

  context ".expect_valid_run_loop" do
    context "raises errors when" do
      it "is passed nil" do
        expect do
          Calabash::Cucumber::Gestures::Instruments.expect_valid_run_loop(nil)
        end.to raise_error ArgumentError, /Expected run_loop arg to be non-nil/
      end

      it "is not passed a hash" do
        expect do
          Calabash::Cucumber::Gestures::Instruments.expect_valid_run_loop([])
        end.to raise_error ArgumentError, /Expected run_loop arg to be a hash/
      end

      context "passed a hash" do
        let(:hash) do
          {
            :pid => 10,
            :udid => :udid,
            :gesture_performer => :instruments,
            :index => 1,
            :log_file => "path/to/log",
            :uia_strategy => Calabash::Cucumber::Gestures::Instruments::UIA_STRATEGIES[0]
          }
        end

        # Legacy - can be removed once run-loop > 2.1.3 is required.
        it "is passed a hash with no :gesture_performer" do
          hash[:gesture_performer] = :client

          expect do
            Calabash::Cucumber::Gestures::Instruments.expect_valid_run_loop(hash)
          end.to raise_error ArgumentError, /Invalid :gesture_performer/
        end

        it "is passed a hash with an invalid :gesture_performer" do
          hash[:gesture_performer] = :invalid
          expect do
            Calabash::Cucumber::Gestures::Instruments.expect_valid_run_loop(hash)
          end.to raise_error ArgumentError, /Invalid :gesture_performer/
        end

        it "is passed a hash that does not have a truthy :udid key" do
          hash[:udid] = nil
          expect do
            Calabash::Cucumber::Gestures::Instruments.expect_valid_run_loop(hash)
          end.to raise_error ArgumentError,
                             /Expected run_loop to have a truthy value for :udid/
        end

        it "is passed a hash that does not have a truthy :pid key" do
          hash[:pid] = nil
          expect do
            Calabash::Cucumber::Gestures::Instruments.expect_valid_run_loop(hash)
          end.to raise_error ArgumentError,
                             /Expected run_loop to have a truthy value for :pid/
        end

        it "is passed a hash that does not have a truthy :index key" do
          hash[:index] = nil
          expect do
            Calabash::Cucumber::Gestures::Instruments.expect_valid_run_loop(hash)
          end.to raise_error ArgumentError,
                             /Expected run_loop to have a truthy value for :index/
        end

        it "is passed a hash that does not have a truthy :log_file" do
          hash[:log_file] = nil
          expect do
            Calabash::Cucumber::Gestures::Instruments.expect_valid_run_loop(hash)
          end.to raise_error ArgumentError,
                             /Expected run_loop to have a truthy value for :log_file/
        end

        it "is passed a hash that does not have a truthy :uia_strategy" do
          hash[:uia_strategy] = nil
          expect do
            Calabash::Cucumber::Gestures::Instruments.expect_valid_run_loop(hash)
          end.to raise_error ArgumentError,
                             /Expected run_loop to have a truthy value for :uia_strategy/
        end

        it "is passed an invalid strategy" do
          expect(Calabash::Cucumber::Gestures::Instruments).to receive(:valid_uia_strategy?).and_return(false)

          expect do
            Calabash::Cucumber::Gestures::Instruments.expect_valid_run_loop(hash)
          end.to raise_error ArgumentError,
                             /to be one of these supported strategies:/
        end

        it "returns true if valid" do
          expect(Calabash::Cucumber::Gestures::Instruments.expect_valid_run_loop(hash)).to be_truthy
        end
      end
    end
  end

  context ".valid_uia_strategy?" do
    context "returns true when" do
      it "is :host" do
        expect(Calabash::Cucumber::Gestures::Instruments.valid_uia_strategy?(:host)).to be_truthy
      end

      it "is :preferences" do
        expect(Calabash::Cucumber::Gestures::Instruments.valid_uia_strategy?(:preferences)).to be_truthy
      end

      it "is :shared_element" do
        expect(Calabash::Cucumber::Gestures::Instruments.valid_uia_strategy?(:shared_element)).to be_truthy
      end
    end

    it "return false if not valid" do
      expect(Calabash::Cucumber::Gestures::Instruments.valid_uia_strategy?(:unsupported)).to be_falsey
    end
  end

  context ".new" do
    it "raises ArgumentError if args are invalid" do
      expect(Calabash::Cucumber::Gestures::Instruments).to receive(:expect_valid_init_args).and_raise ArgumentError

      expect do
        Calabash::Cucumber::Gestures::Instruments.new(nil)
      end.to raise_error ArgumentError
    end

    it "returns a new instance" do
      expect(Calabash::Cucumber::Gestures::Instruments).to receive(:expect_valid_init_args).and_return true
      args = {:run_loop => true}
      actual = Calabash::Cucumber::Gestures::Instruments.new(args)

      expect(actual.instance_variable_get(:@run_loop)).to be == args
    end
  end

  context "instance methods" do
    let(:run_loop) do
      {
        :pid => 10,
        :udid => :udid,
        :gesture_performer => :instruments,
        :index => 1,
        :log_file => "path/to/log",
        :uia_strategy => Calabash::Cucumber::Gestures::Instruments::UIA_STRATEGIES[0]
      }
    end

    let(:instruments) { Calabash::Cucumber::Gestures::Instruments.new(run_loop) }

    context "#rotate_with_uia" do
      it "calls uia with the correct command" do
        expect(instruments).to receive(:orientation_key).with(:direction, :orientation).and_return(:key)
        expect(instruments).to receive(:orientation_for_key).with(:key).and_return(10)
        cmd = "UIATarget.localTarget().setDeviceOrientation(10)"
        expect(instruments).to receive(:uia).with(cmd).and_return(:success)

        actual = instruments.send(:rotate_with_uia, :direction, :orientation)
        expect(actual).to be == :success
      end
    end

    context "#rotate_home_button_to" do
      it "rotates" do
        expect(instruments).to receive(:rotate_to_uia_orientation).with(:down).and_return :success
        expect(instruments).to receive(:recalibrate_after_rotation).and_return(:success)
        expect(instruments).to receive(:status_bar_orientation).and_return('after')

        expect(instruments.rotate_home_button_to(:down)).to be == :after
      end
    end

    context "#rotate" do

      before do
        expect(instruments).to receive(:status_bar_orientation).and_return(:before, :after)
        expect(instruments).to receive(:rotate_with_uia).and_return :orientation
        expect(instruments).to receive(:recalibrate_after_rotation).and_return(:success)
      end

      it ':left' do expect(instruments.rotate(:left)).to be == :after end
      it ':right' do expect(instruments.rotate(:right)).to be == :after end
    end

    it '#rotate_with_uia' do
      expect(instruments).to receive(:orientation_key).and_return :key
      stub_const('Calabash::Cucumber::RotationHelpers::DEVICE_ORIENTATION', {:key => 'value' })
      expected = 'UIATarget.localTarget().setDeviceOrientation(value)'
      expect(instruments).to receive(:uia).with(expected).and_return :result

      expect(instruments.send(:rotate_with_uia, :left, :down)).to be == :result
    end

    it "#recalibrate_afer_rotation" do
      expect(instruments).to receive(:uia_query).with(:window).and_return :success

      expect(instruments.send(:recalibrate_after_rotation)).to be == :success
    end

    describe '#rotate_to_uia_orientation' do
      it 'raises an error for invalid arguments' do
        expect do
          instruments.send(:rotate_to_uia_orientation, :invalid)
        end.to raise_error ArgumentError, /Expected/
      end

      describe 'valid arguments' do
        it ':down' do
          expected = 'UIATarget.localTarget().setDeviceOrientation(1)'
          expect(instruments).to receive(:uia).with(expected).and_return :result

          actual = instruments.send(:rotate_to_uia_orientation, :down)
          expect(actual).to be == :result
        end

        it ':up' do
          expected = 'UIATarget.localTarget().setDeviceOrientation(2)'
          expect(instruments).to receive(:uia).with(expected).and_return :result

          actual = instruments.send(:rotate_to_uia_orientation, :up)
          expect(actual).to be == :result

        end

        it ':left' do
          expected = 'UIATarget.localTarget().setDeviceOrientation(4)'
          expect(instruments).to receive(:uia).with(expected).and_return :result

          actual = instruments.send(:rotate_to_uia_orientation, :left)
          expect(actual).to be == :result

        end

        it ':right' do
          expected = 'UIATarget.localTarget().setDeviceOrientation(3)'
          expect(instruments).to receive(:uia).with(expected).and_return :result

          actual = instruments.send(:rotate_to_uia_orientation, :right)
          expect(actual).to be == :result
        end
      end
    end
  end
end

