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

    it 'iOS >= 9' do
      expect(helper).to receive(:ios_version).and_return RunLoop::Version.new('9.0')
      expect(helper).to receive(:rotate_to_uia_orientation).with(:down).and_return :rotation_result
      expect(helper).to receive(:recalibrate_after_rotation).and_call_original
      expect(helper).to receive(:status_bar_orientation).and_return('before', 'after')

      expect(helper.rotate_home_button_to('down')).to be == :after
    end

    it 'iOS < 9' do
      expect(helper).to receive(:ios_version).and_return RunLoop::Version.new('8.0')
      expect(helper).to receive(:status_bar_orientation).and_return('before')
      expect(helper).to receive(:rotate_home_button_to_position_with_playback).with(:down).and_return :after

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
          expect(helper).to receive(:ios_version).and_return RunLoop::Version.new('9.0')
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

    it 'iOS 9' do
      expect(helper).to receive(:ios_version).and_return RunLoop::Version.new('9.0')
      expect(helper).to receive(:status_bar_orientation).and_return(:before, :after)
      expect(helper).to receive(:rotate_with_uia).with(:left, :before).and_return :orientation
      expect(helper).to receive(:recalibrate_after_rotation).and_call_original

      expect(helper.rotate(:left)).to be == :after
    end

    it 'iOS < 9' do
      expect(helper).to receive(:ios_version).and_return RunLoop::Version.new('8.0')
      expect(helper).to receive(:status_bar_orientation).and_return(:before, :after)
      expect(helper).to receive(:rotate_with_playback).with(:left, :before).and_return :orientation
      expect(helper).to receive(:recalibrate_after_rotation).and_call_original

      expect(helper.rotate(:left)).to be == :after
    end
  end

  it '#rotate_with_uia' do
    expect(helper).to receive(:uia_orientation_key).and_return :key
    stub_const('Calabash::Cucumber::RotationHelpers::UIA_DEVICE_ORIENTATION', {:key => 'value' })
    expected = 'UIATarget.localTarget().setDeviceOrientation(value)'
    expect(helper).to receive(:uia).with(expected).and_return :result

    expect(helper.send(:rotate_with_uia, :left, :down)).to be == :result
  end

  it '#rotate_with_playback' do
    expect(helper).to receive(:recording_name).and_return 'recording name'
    expect(helper).to receive(:playback).with('recording name').and_return :result

    expect(helper.send(:rotate_with_playback, :left, :down)).to be == :result
  end

  describe '#uia_orientation_key' do
    describe ':left' do
      it ':down' do helper.send(:uia_orientation_key, :left, :down) == :landscape_right end
      it ':right' do helper.send(:uia_orientation_key, :left, :right) == :portrait end
      it ':left' do helper.send(:uia_orientation_key, :left, :left) == :upside_down end
      it ':up' do helper.send(:uia_orientation_key, :left, :up) == :landscape_left end
    end

    describe ':right' do
      it ':down' do helper.send(:uia_orientation_key, :right, :down) == :landscape_left end
      it ':right' do helper.send(:uia_orientation_key, :right, :right) == :upside_down end
      it ':left' do helper.send(:uia_orientation_key, :right, :left) == :portrait end
      it ':up' do helper.send(:uia_orientation_key, :right, :up) == :landscape_right end
    end
  end

  describe '#recording_name' do
    describe ':left' do
      it ':down' do
        helper.send(:recording_name, :left, :down) == 'rotate_left_home_down'
      end

      it ':right' do
        helper.send(:recording_name, :left, :right) == 'rotate_left_home_right'
      end

      it ':left' do
        helper.send(:recording_name, :left, :left) == 'rotate_left_home_left'
      end

      it ':up' do
        helper.send(:recording_name, :left, :up) == 'rotate_left_home_up'
      end
    end

    describe ':right' do
      it ':down' do
        helper.send(:recording_name, :left, :down) == 'rotate_right_home_down'
      end

      it ':right' do
        helper.send(:recording_name, :left, :right) == 'rotate_right_home_right'
      end

      it ':left' do
        helper.send(:recording_name, :left, :left) == 'rotate_right_home_left'
      end

      it ':up' do
        helper.send(:recording_name, :left, :up) == 'rotate_right_home_up'
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
