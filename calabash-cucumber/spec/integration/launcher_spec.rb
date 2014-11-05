describe 'Calabash Launcher' do
  let(:launcher) { Calabash::Cucumber::Launcher.new }
  let(:fake_udid) { 'FAKE-UDID' }
  describe 'reset_simulator' do
    context 'when running on a device' do
      before { ENV['DEVICE_TARGET'] = fake_udid }
      it 'raises an error' do
        expect {  launcher.reset_simulator  }.to raise_error(RuntimeError)
      end
    end

    context 'when running on the simulator' do
      before { ENV.delete('DEVICE_TARGET') }
      it 'successfully resets the simulator' do
        launcher.reset_simulator
      end
    end
  end
end
