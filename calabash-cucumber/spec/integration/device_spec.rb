unless Luffa::Environment.travis_ci?
  describe Calabash::Cucumber::Device do

    before do
      RunLoop::SimControl.terminate_all_sims
    end

    let(:endpoint) { 'http://localhost:37265' }
    let(:xcode) { Resources.shared.xcode }

    describe '#form_factor' do
      let(:device)  do
        options = {
              :app => Resources.shared.app_bundle_path(:cal_smoke_app),
              :device_target =>  device_target,
              :xcode => xcode,
              :sim_control => Resources.shared.sim_control,
              :launch_retries => Luffa::Retry.instance.launch_retries
        }
        launcher = Calabash::Cucumber::Launcher.new
        launcher.relaunch(options)
        launcher.device
      end

      subject { device.form_factor }

      context 'device is an ipad' do
        let(:device_target) {
          if xcode.version_gte_6?
            Resources.shared.simulator_identifier_with_name('iPad Retina')
          else
            'iPad Retina (64-bit) - Simulator - iOS 7.1'
          end
        }
        it { is_expected.to be == 'ipad' }
      end

      context 'iPhone 5 is an 4in iphone' do
        let(:device_target) {
          if xcode.version_gte_6?
            Resources.shared.simulator_identifier_with_name('iPhone 5')
          else
            'iPhone Retina (4-inch) - Simulator - iOS 7.1'
          end
        }
        it { is_expected.to be == 'iphone 4in' }
      end

      context 'iPhone 5s is an 4in iphone' do
        let(:device_target) {
          if xcode.version_gte_6?
            Resources.shared.simulator_identifier_with_name('iPhone 5s')
          else
            'iPhone Retina (4-inch) - Simulator - iOS 7.1'
          end
        }
        it { is_expected.to be == 'iphone 4in' }
      end

      context 'device is a 3.5" iphone' do
        let(:device_target) {
          if xcode.version_gte_6?
            Resources.shared.simulator_identifier_with_name('iPhone 4s')
          else
            'iPhone Retina (3.5-inch) - Simulator - iOS 7.1'
          end
        }
        it { is_expected.to be == 'iphone 3.5in' }
      end

      context 'device is an iphone 6' do
        let(:device_target) {
          if xcode.version_gte_6?
            Resources.shared.simulator_identifier_with_name('iPhone 6')
          else
            # iPhone 6 does not exist on Xcode < 6
            nil
          end
        }
        it { is_expected.to be == 'iphone 6' if device_target }
      end

      context 'device is an iphone 6+' do
        let(:device_target) {
          if xcode.version_gte_6?
            Resources.shared.simulator_identifier_with_name('iPhone 6 Plus')
          else
            # iPhone 6 does not exist on Xcode < 6
            nil
          end
        }
        it { is_expected.to be == 'iphone 6+' if device_target }
      end
    end
  end
end
