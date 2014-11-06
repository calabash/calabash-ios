describe 'Calabash Launcher' do
  let(:launcher) { Calabash::Cucumber::Launcher.new }
  let(:fake_udid) { 'FAKE-UDID' }
  describe 'reset_simulator' do
    context 'when running on a device' do
      it 'raises an error' do
        stub_env('DEVICE_TARGET', fake_udid)
        expect {  launcher.reset_simulator  }.to raise_error(RuntimeError)
      end
    end

    context 'when running on the simulator' do
      it 'successfully resets the simulator' do
        stub_env('DEVICE_TARGET', nil)
        launcher.reset_simulator
      end
    end
  end
end
