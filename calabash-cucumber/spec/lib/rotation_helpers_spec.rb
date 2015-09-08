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
    describe 'validates arguments' do
      it 'raises error on invalid arguments' do
        expect do
          helper.rotate(:invalid)
          end.to raise_error ArgumentError, /Expected/
      end

      describe 'valid arguments' do

        before do
          expect(helper).to receive(:ios_version).and_return RunLoop::Version.new('9.0')
          expect(helper).to receive(:status_bar_orientation).and_return :current
          expect(helper).to receive(:rotate_with_uia).and_return :orientation
          expect(helper).to receive(:recalibrate_after_rotation).and_call_original
        end

        it 'left' do expect(helper.rotate('left')).to be == :orientation end
        it ':left' do expect(helper.rotate(:left)).to be == :orientation end
        it 'right' do expect(helper.rotate('right')).to be == :orientation end
        it ':right' do expect(helper.rotate(:right)).to be == :orientation end
      end
    end

    it 'iOS 9' do
      expect(helper).to receive(:ios_version).and_return RunLoop::Version.new('9.0')
      expect(helper).to receive(:status_bar_orientation).and_return :current
      expect(helper).to receive(:rotate_with_uia).with(:left, :current).and_return :orientation
      expect(helper).to receive(:recalibrate_after_rotation).and_call_original

      expect(helper.rotate(:left)).to be == :orientation
    end

    it 'iOS < 9' do
      expect(helper).to receive(:ios_version).and_return RunLoop::Version.new('8.0')
      expect(helper).to receive(:status_bar_orientation).and_return :current
      expect(helper).to receive(:rotate_with_playback).with(:left, :current).and_return :orientation
      expect(helper).to receive(:recalibrate_after_rotation).and_call_original

      expect(helper.rotate(:left)).to be == :orientation
    end
  end

  describe '.rotate_with_uia' do
    it 'raises error' do
      expect do
        helper.send(:rotate_with_uia, :invalid, :orientation)
      end.to raise_error ArgumentError
    end


  end

  describe '.rotate_with_playback' do
    it 'raises error' do
      expect do
        helper.send(:rotate_with_playback, :invalid, :orienation)
      end.to raise_error ArgumentError
    end
  end
end
