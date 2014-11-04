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

  describe 'default launch args should respect DEVICE_TARGET' do

    it "should return 'simulator' if DEVICE_TARGET nil" do
      args = launcher.default_launch_args
      expect(args[:device_target]).to be == 'simulator'
    end

    describe 'running with instruments' do

      it 'should be running against instruments' do
        args = launcher.default_launch_args
        expect(args[:launch_method]).to be == :instruments
      end

      describe 'running against devices' do

        describe 'when DEVICE_TARGET = < udid >' do
          before(:each) do
            ENV['DEVICE_TARGET'] = fake_udid
          end

          it 'it should return udid if DEVICE_TARGET is a udid' do
            args = launcher.default_launch_args
            expect(args[:device_target]).to be == fake_udid
            expect(args[:udid]).to be == fake_udid
          end
        end

        describe 'when DEVICE_TARGET = device' do
          before(:each) do
            ENV['DEVICE_TARGET'] = 'device'
          end

          describe 'detecting connected devices' do
            describe "when DETECT_CONNECTED_DEVICE == '1'" do
              it 'should return a udid if DEVICE_TARGET=device if a device is connected and simulator otherwise' do
                ENV['DETECT_CONNECTED_DEVICE'] = '1'
                args = launcher.default_launch_args
                target = args[:device_target]
                detected = RunLoop::Core.detect_connected_device

                if detected
                  expect(target).to be == detected
                  expect(args[:udid]).to be == detected
                else
                  #pending('this behavior is needs verification')
                  expect(target).to be == 'simulator'
                end
              end

              context "when DETECT_CONNECTED_DEVICE != '1'" do
                before { ENV.delete('DETECT_CONNECTED_DEVICE') }
                it 'should return a udid if DEVICE_TARGET=device if a device is connected and simulator otherwise' do
                  args = launcher.default_launch_args
                  target = args[:device_target]
                  expect(target).to be == 'device'
                  expect(args[:udid]).to be == 'device'
                end
              end
            end
          end
        end
      end

      describe 'running against simulators' do

        describe 'DEVICE_TARGET is an iphone in Xcode 5.1 format' do
          let(:device_target) { 'FAKE DEVICE TARGET' }
          before(:each) do
            ENV['DEVICE_TARGET'] = device_target
          end

          it 'should return the correct simulator' do
            args = launcher.default_launch_args
            expect(args[:device_target]).to be == device_target
          end

        end

      end
    end
  end

  describe '#attach' do
    it 'can attach to a running instruments instance' do
      sim_control = RunLoop::SimControl.new
      options =
            {
                  :app => Resources.shared.app_bundle_path(:lp_simple_example),
                  :device_target => 'simulator',
                  :no_stop => true,
                  :sim_control => sim_control,
                  :launch_retries => Resources.shared.travis_ci? ? 5 : 2
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
