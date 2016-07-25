describe Calabash::Cucumber::RotationHelpers do

  let(:helper) do
    Class.new do
      include Calabash::Cucumber::RotationHelpers
      include Calabash::Cucumber::EnvironmentHelpers

      def uia_query(_); ; end
      def status_bar_orientation; ; end
      def uia(_); ; end
      def playback(_); ; end
    end.new
  end

  before do
    stub_env({'DEBUG' => '1'})
  end

  describe '#rotate_home_button_to' do
    it 're-raises ArgumentError' do
      error = ArgumentError.new('Expect ArgumentError')
      expect(helper).to receive(:ensure_valid_rotate_home_to_arg).and_raise error

      expect do
        helper.rotate_home_button_to(:invalid)
      end.to raise_error ArgumentError, /Expect ArgumentError/
    end

    it 'does nothing if device is already in the target orientation' do
      expect(helper).to receive(:ensure_valid_rotate_home_to_arg).and_return :down
      expect(helper).to receive(:status_bar_orientation).and_return 'down'

      expect(helper.rotate_home_button_to('down')).to be == :down
    end

    it 'rotates' do
      expect(helper).to receive(:rotate_to_uia_orientation).with(:down).and_return :rotation_result
      expect(helper).to receive(:recalibrate_after_rotation).and_call_original
      expect(helper).to receive(:status_bar_orientation).and_return('before', 'after')

      expect(helper.rotate_home_button_to('down')).to be == :after
    end
  end

  describe '#rotate' do
    describe 'validates arguments' do
      it 'raises error on invalid arguments' do
        expect do
          helper.rotate(:invalid)
          end.to raise_error ArgumentError, /Expected/
      end

      describe 'valid arguments' do

        before do
          expect(helper).to receive(:status_bar_orientation).and_return(:before, :after)
          expect(helper).to receive(:rotate_with_uia).and_return :orientation
          expect(helper).to receive(:recalibrate_after_rotation).and_call_original
        end

        it 'left' do expect(helper.rotate('left')).to be == :after end
        it ':left' do expect(helper.rotate(:left)).to be == :after end
        it 'right' do expect(helper.rotate('right')).to be == :after end
        it ':right' do expect(helper.rotate(:right)).to be == :after end
      end
    end

    it 'rotates' do
      expect(helper).to receive(:status_bar_orientation).and_return(:before, :after)
      expect(helper).to receive(:rotate_with_uia).with(:left, :before).and_return :orientation
      expect(helper).to receive(:recalibrate_after_rotation).and_call_original

      expect(helper.rotate(:left)).to be == :after
    end
  end

  it '#rotate_with_uia' do
    expect(helper).to receive(:orientation_key).and_return :key
    stub_const('Calabash::Cucumber::RotationHelpers::DEVICE_ORIENTATION', {:key => 'value' })
    expected = 'UIATarget.localTarget().setDeviceOrientation(value)'
    expect(helper).to receive(:uia).with(expected).and_return :result

    expect(helper.send(:rotate_with_uia, :left, :down)).to be == :result
  end

  describe '#uia_orientation_key' do
    describe 'rotate :left' do
      it 'returns :landscape_left when home button is :down' do
        expect(helper.send(:orientation_key, :left, :down)).to be == :landscape_left
      end

      it 'returns :upside_down when home button is :right' do
        expect(helper.send(:orientation_key, :left, :right)).to be == :upside_down
      end

      it 'returns :portrait with home button is :left' do
        expect(helper.send(:orientation_key, :left, :left)).to be == :portrait
      end

      it 'returns :landscape_right when the home button is :up' do
        expect(helper.send(:orientation_key, :left, :up)).to be == :landscape_right
      end
    end

    describe 'rotate :right' do
      it 'returns :landscape_right when home button is :down' do
        expect(helper.send(:orientation_key, :right, :down)).to be == :landscape_right
      end

      it 'returns :portrait when home button is :right' do
        expect(helper.send(:orientation_key, :right, :right)).to be == :portrait
      end

      it 'returns :upside_down when home button is :left' do
        expect(helper.send(:orientation_key, :right, :left)).to be == :upside_down
      end

      it 'returns :landscape_left when home button is :up' do
        expect(helper.send(:orientation_key, :right, :up)).to be == :landscape_left
      end
    end
  end

  describe '#rotate_to_uia_orientation' do
    it 'raises an error for invalid arguments' do
      expect do
        helper.send(:rotate_to_uia_orientation, :invalid)
      end.to raise_error ArgumentError, /Expected/
    end

    describe 'valid arguments' do
      it ':down' do
        expected = 'UIATarget.localTarget().setDeviceOrientation(1)'
        expect(helper).to receive(:uia).with(expected).and_return :result

        actual = helper.send(:rotate_to_uia_orientation, :down)
        expect(actual).to be == :result
      end

      it ':up' do
        expected = 'UIATarget.localTarget().setDeviceOrientation(2)'
        expect(helper).to receive(:uia).with(expected).and_return :result

        actual = helper.send(:rotate_to_uia_orientation, :up)
        expect(actual).to be == :result

      end

      it ':left' do
        expected = 'UIATarget.localTarget().setDeviceOrientation(4)'
        expect(helper).to receive(:uia).with(expected).and_return :result

        actual = helper.send(:rotate_to_uia_orientation, :left)
        expect(actual).to be == :result

      end

      it ':right' do
        expected = 'UIATarget.localTarget().setDeviceOrientation(3)'
        expect(helper).to receive(:uia).with(expected).and_return :result

        actual = helper.send(:rotate_to_uia_orientation, :right)
        expect(actual).to be == :result
      end
    end
  end

  describe '#ensure_valid_rotate_home_to_arg' do
    it 'raises error when arg is invalid' do
      expect do
        helper.send(:ensure_valid_rotate_home_to_arg, :invalid)
      end.to raise_error ArgumentError, /Expected/
    end

    describe 'valid arguments' do
      it 'top' do
        expect(helper.send(:ensure_valid_rotate_home_to_arg, 'top')).to be == :up
      end

      it ':top' do
        expect(helper.send(:ensure_valid_rotate_home_to_arg, :top)).to be == :up
      end

      it 'bottom' do
        expect(helper.send(:ensure_valid_rotate_home_to_arg, 'bottom')).to be == :down
      end

      it ':bottom' do
        expect(helper.send(:ensure_valid_rotate_home_to_arg, :bottom)).to be == :down
      end
    end
  end
end
