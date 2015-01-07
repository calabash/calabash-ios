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

  describe '#attach' do
    it 'can attach to a running instruments instance' do
      stub_env('DEVICE_TARGET', nil)
      sim_control = RunLoop::SimControl.new
      options =
            {
                  :app => Resources.shared.app_bundle_path(:lp_simple_example),
                  :device_target => 'simulator',
                  :no_stop => true,
                  :sim_control => sim_control,
                  :launch_retries => Resources.shared.launch_retries
            }
      launcher.relaunch(options)
      expect(launcher.run_loop).not_to be == nil

      other_launcher = Calabash::Cucumber::Launcher.new
      other_launcher.attach

      expect(other_launcher.run_loop).not_to be nil
      expect(other_launcher.run_loop[:uia_strategy]).to be == :preferences

      Open3.popen3('sh') do |stdin, stdout, stderr, _|
        stdin.puts 'bundle exec calabash-ios console <<EOF'
        stdin.puts 'console_attach'
        stdin.puts "touch 'textField'"
        stdin.puts 'EOF'
        stdin.close
        expect(stdout.read.strip[/Error/,0]).to be == nil
        expect(stderr.read.strip).to be == ''
      end
    end
  end
end
