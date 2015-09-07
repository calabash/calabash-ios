describe Calabash::Cucumber::RotationHelpers do

  let(:helper) do
    Class.new do
      include Calabash::Cucumber::RotationHelpers
      include Calabash::Cucumber::EnvironmentHelpers

      def uia_query(_); ; end
      def status_bar_orientation; ; end
    end.new
  end


  describe '.rotate' do
    it 'iOS 9' do
      expect(helper).to receive(:ios_version).and_return RunLoop::Version.new('9.0')
      expect(helper).to receive(:rotate_with_uia).with(:left).and_return :orientation
      expect(helper).to receive(:recalibrate_after_rotation).and_call_original

      expect(helper.rotate(:left)).to be == :orientation
    end

    it 'iOS < 9' do
      expect(helper).to receive(:ios_version).and_return RunLoop::Version.new('8.0')
      expect(helper).to receive(:rotate_with_playback).with(:left).and_return :orientation
      expect(helper).to receive(:recalibrate_after_rotation).and_call_original

      expect(helper.rotate(:left)).to be == :orientation
    end
  end

  describe '.rotate_with_uia' do
    it 'raises error' do
      expect(helper).to receive(:status_bar_orientation).and_return :orientation

      expect do
        helper.send(:rotate_with_uia, :invalid)
      end.to raise_error ArgumentError
    end
  end

  describe '.rotate_with_playback' do
    it 'raises error' do
      expect(helper).to receive(:status_bar_orientation).and_return :orientation

      expect do
        helper.send(:rotate_with_playback, :invalid)
      end.to raise_error ArgumentError
    end
  end
end
