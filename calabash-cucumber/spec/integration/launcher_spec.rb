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
    before(:each) {   stub_env('DEVICE_TARGET', nil) }
    let(:launch_options) {
      {
            :app => Resources.shared.app_bundle_path(:lp_simple_example),
            :device_target => 'simulator',
            :no_stop => true,
            :sim_control => RunLoop::SimControl.new,
            :launch_retries => Resources.shared.launch_retries
      }
    }

    let(:other_launcher) { Calabash::Cucumber::Launcher.new }

    def calabash_console_with_strategy(strategy=nil)
      if strategy.nil?
        attach_cmd = 'console_attach'
      else
        # Super weird, but we need to force the : here.
        attach_cmd = "console_attach(:#{strategy})"
      end
      Open3.popen3('sh') do |stdin, stdout, stderr, _|
        stdin.puts 'bundle exec calabash-ios console <<EOF'
        stdin.puts attach_cmd
        stdin.puts "touch 'textField'"
        stdin.puts 'EOF'
        stdin.close
        yield stdout, stderr
      end
    end

    describe 'can connect to launched apps' do

      before(:each) { FileUtils.rm_rf(RunLoop::HostCache.default_directory) }

      [:preferences, :host, :shared_element].shuffle.each do |strategy|
        it strategy do

          launch_options[:uia_strategy] = strategy

          launcher.relaunch(launch_options)
          expect(launcher.run_loop).not_to be == nil

          other_launcher.attach({:uia_strategy => strategy})

          expect(other_launcher.run_loop).not_to be nil
          expect(other_launcher.run_loop[:uia_strategy]).to be == strategy

          calabash_console_with_strategy(strategy) do |stdout, stderr|
            expect(stdout.read.strip[/Error/,0]).to be == nil
            expect(stderr.read.strip).to be == ''
          end
        end
      end
    end
  end
end
