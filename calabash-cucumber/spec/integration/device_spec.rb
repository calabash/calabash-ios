unless Luffa::Environment.travis_ci?
  describe Calabash::Cucumber::Device do

    before do
      RunLoop::SimControl.terminate_all_sims
    end

    let(:endpoint) { 'http://localhost:37265' }
    let(:xcode) { Resources.shared.xcode }
    let(:simctl) { Resources.shared.simctl }
    let(:instruments) { Resources.shared.instruments }

    it 'sets instance variables' do
      device_target = Resources.shared.simulator_identifier_with_name('iPhone 5s')
      options = {
            :app => Resources.shared.app_bundle_path(:cal_smoke_app),
            :device_target =>  device_target,
            :xcode => xcode,
            :simctl => simctl,
            :instruments => instruments,
            :launch_retries => Luffa::Retry.instance.launch_retries
      }
      launcher = Calabash::Cucumber::Launcher.new
      launcher.relaunch(options)
      device = launcher.device

      expect(device.model_identifier).to be == 'iPhone6,1'
      expect(device.device_family).to be == 'iPhone'
      expect(device.simulator_details[/CoreSimulator/,0]).to be_truthy
      expect(device.ios_version).to be_truthy
      expect(device.server_version).to be_truthy
      expect(device.iphone_app_emulated_on_ipad?).to be_falsey
      expect(device.form_factor).to be == 'iphone 4in'
      expect(device.device_name).to be == 'iPhone Simulator'
      expect(device.screen_dimensions.count).to be == 5
    end

    describe '#form_factor' do

      let(:device)  do
        options = {
              :app => Resources.shared.app_bundle_path(:cal_smoke_app),
              :device_target =>  device_target,
              :xcode => xcode,
              :simctl => simctl,
              :instruments => instruments,
              :launch_retries => Luffa::Retry.instance.launch_retries
        }
        launcher = Calabash::Cucumber::Launcher.new
        launcher.relaunch(options)
        launcher.device
      end

      subject { device.form_factor }

      context 'device is an ipad' do
        let(:device_target) do
          Resources.shared.simulator_identifier_with_name('iPad Retina')
        end
        it { is_expected.to be == 'ipad' }
      end

      context 'iPhone 5 is an 4in iphone' do
        let(:device_target) do
          Resources.shared.simulator_identifier_with_name('iPhone 5')
        end
        it { is_expected.to be == 'iphone 4in' }
      end

      context 'iPhone 5s is an 4in iphone' do
        let(:device_target) do
          Resources.shared.simulator_identifier_with_name('iPhone 5s')
        end
        it { is_expected.to be == 'iphone 4in' }
      end

      context 'device is a 3.5" iphone' do
        let(:device_target) do
          Resources.shared.simulator_identifier_with_name('iPhone 4s')
        end
        it { is_expected.to be == 'iphone 3.5in' }
      end

      context 'device is an iphone 6' do
        let(:device_target) do
          Resources.shared.simulator_identifier_with_name('iPhone 6')
        end
        it { is_expected.to be == 'iphone 6' }
      end

      context 'device is an iphone 6+' do
        let(:device_target) do
          Resources.shared.simulator_identifier_with_name('iPhone 6 Plus')
        end
        it { is_expected.to be == 'iphone 6+' }
      end
    end
  end
end
