

module Calabash
  module Rspec
    module ResetAppSandbox
      class Helper

        # Xcode 5

        SIM_SDK_DIR_REGEX = /(\d)\.(\d)\.?(\d)?(-64)?/
        SANDBOX_DIRS = ['Library', 'Documents', 'tmp']

        def sandbox_dirs
          SANDBOX_DIRS
        end

        def sim_sdk_dir_regex
          SIM_SDK_DIR_REGEX
        end

        def populate_app_sandbox(path=args_for_reset_app_sandbox[:path])
          app_udid_dir = File.expand_path(File.join(path, '..'))
          SANDBOX_DIRS.each do |dir|
            dir_path = File.expand_path(File.join(app_udid_dir, dir))
            FileUtils.mkdir_p(dir_path)
          end
          app_udid_dir
        end

        def args_for_reset_app_sandbox(sdk='7.1')
          sub_dir = 'resources/launcher'
          dir_udid = '1FCBF253-E5EC-4FD5-839D-0AC526F28D10'
          app_name = 'LPSimpleExample-cal.app'
          joined = File.join(__FILE__, '..', sub_dir, sdk, 'Applications', dir_udid, app_name)
          {
                :path => File.expand_path(joined),
                :sdk => sdk
          }
        end

        # Xcode 6

        # Apple bug.  Cannot launch 7.0.3 simulators.
        # http://openradar.appspot.com/radar?id=5221532267708416
        #
        # Travis CI CoreSimulator environment is not stable. :(
        def random_core_simulator(sim_control)
          if Resources.shared.travis_ci?
            ios8 = RunLoop::Version.new('8.0')
            target_simulator = nil
            sim_control.simulators.each do |device|
              if device.name == 'iPad Air' and device.version == ios8
                target_simulator = device
              end
            end
            target_simulator
          else
            min_ios_version = RunLoop::Version.new('7.1')
            sim_control.simulators.delete_if { |device| device.version < min_ios_version }.sample
          end
        end

        # Should be part of run-loop.
        # https://github.com/calabash/run_loop/issues/51
        def instruments_launch_name(simulator)
          "#{simulator.name} (#{simulator.version.to_s} Simulator)"
        end

        def launch_options(sim_control, target)
          {
                :app => Resources.shared.app_bundle_path(:lp_simple_example),
                :device_target => target,
                :sim_control => sim_control,
                :launch_retries => Resources.shared.travis_ci? ? 5 : 2
          }
        end

        def default_simulator_as_device(sim_control)
          default_sim = RunLoop::Core.default_simulator(sim_control.xctools)
          target_simulator = nil
          sim_control.simulators.each do |device|
            instruments_launch_name = "#{device.name} (#{device.version.to_s} Simulator)"
            if instruments_launch_name == default_sim
              target_simulator = device
            end
          end
          target_simulator
        end

        def launch_and_stop_simulator(launcher, sim_control, target)
          options = launch_options(sim_control, target)
          launcher.relaunch(options)
          sleep(1.0)
          launcher.stop
        end

        def path_to_sim_app_bundles(udid, simulator)
          sim_path = File.expand_path("~/Library/Developer/CoreSimulator/Devices/#{udid}")
          if simulator.version >= RunLoop::Version.new('8.0')
            File.expand_path(File.join(sim_path, 'data', 'Containers', 'Bundle', 'Application'))
          else
            File.expand_path(File.join(sim_path, 'data', 'Applications'))
          end
        end

        def installed_apps(udid, simulator)
          app_bundles = path_to_sim_app_bundles(udid, simulator)
          Dir.glob("#{app_bundles}/**/*.app").map { |abp| File.basename(abp) }
        end

        def path_to_containers(udid, simulator)
          sim_path = File.expand_path("~/Library/Developer/CoreSimulator/Devices/#{udid}")
          if simulator.version >= RunLoop::Version.new('8.0')
            File.expand_path(File.join(sim_path, 'data', 'Containers'))
          else
            File.expand_path(File.join(sim_path, 'data', 'Applications'))
          end
        end
      end
    end
  end
end

describe Calabash::Cucumber::Launcher do

  before(:each) {
    ENV.delete('DEVELOPER_DIR')
    ENV.delete('DEBUG')
    ENV.delete('DEVICE_TARGET')
    RunLoop::SimControl.terminate_all_sims
  }

  after(:each) {
    ENV.delete('DEVELOPER_DIR')
    ENV.delete('DEBUG')
    ENV.delete('DEVICE_ENDPOINT')
    ENV.delete('DEVICE_TARGET')
  }

  let(:launcher) { Calabash::Cucumber::Launcher.new }

  describe '#reset_app_sandbox' do
    it 'generates a warning if called against a device' do
      expect(launcher).to receive(:device_target?).and_return(true)
      out = capture_stderr do
        launcher.reset_app_sandbox
      end
      expect(out.string).not_to be == ''
    end

    describe 'Xcode < 6' do
      xcode_selected = Resources.shared.xcode_select_xcode_hash
      xcode_installs = Resources.shared.alt_xcodes_gte_xc51_hash + [xcode_selected]
      max_version = RunLoop::Version.new('5.1.1')
      xcode5 = xcode_installs.delete_if { |hash| hash[:version] > max_version }.sample
      if xcode5.nil?
        it 'no Xcode < 6 was found' do
          expect(true).to be == true
        end
      else
        describe "Xcode #{xcode5[:version]}" do

          let(:helper) { Calabash::Rspec::ResetAppSandbox::Helper.new }

          it 'should remove the correct items from the sandbox' do
            ENV['DEVELOPER_DIR'] = xcode5[:path]
            args = helper.args_for_reset_app_sandbox '7.1'

            # make the expected directories and expect they are there
            app_udid_path = helper.populate_app_sandbox(args[:path])
            directories = Dir.glob("#{app_udid_path}/*").select {|f| File.directory? f }
            expected = ['LPSimpleExample-cal.app'].concat(helper.sandbox_dirs)
            expect(directories.map { |dir| File.basename(dir) }).to match_array(expected)

            # need to mock the output of directories_for_sdk_prefix method by mocking
            # the simulator_app_support_dir method
            mocked_support_dir = File.expand_path(File.join(__FILE__, '..', 'resources/launcher'))
            expect(launcher).to receive(:simulator_app_support_dir).and_return(mocked_support_dir)

            launcher.reset_app_sandbox(args)
            directories = Dir.glob("#{app_udid_path}/*").select {|f| File.directory? f }
            expect(directories.map { |dir| File.basename(dir) }).to contain_exactly('LPSimpleExample-cal.app')
          end

          it 'should remove the correct items from _all_ sandboxes when pass :all' do
            ENV['DEVELOPER_DIR'] = xcode5[:path]
            support_dir = File.expand_path(File.join(__FILE__, '..', 'resources/launcher'))
            sdks = Dir["#{support_dir}/*"].select { |x| x =~ helper.sim_sdk_dir_regex }.map { |x| File.basename(x) }
            app_udid_paths = []
            sdks.each do |sdk|
              args = helper.args_for_reset_app_sandbox sdk
              app_udid_path = helper.populate_app_sandbox(args[:path])
              app_udid_paths << app_udid_path
              directories = Dir.glob("#{app_udid_path}/*").select {|f| File.directory? f }
              expected = ['LPSimpleExample-cal.app'].concat(helper.sandbox_dirs)
              expect(directories.map { |dir| File.basename(dir) }).to match_array(expected)
            end

            expect(launcher).to receive(:simulator_app_support_dir).and_return(support_dir)
            # we need the :path to be set correctly and then we can change to :all
            args = helper.args_for_reset_app_sandbox('7.1')
            args[:sdk ] = :all
            launcher.reset_app_sandbox(args)
            app_udid_paths.each do |app_udid_path|
              directories = Dir.glob("#{app_udid_path}/*").select {|f| File.directory? f }
              expect(directories.map { |dir| File.basename(dir) }).to contain_exactly('LPSimpleExample-cal.app')
            end
          end
        end
      end
    end

    describe 'Xcode >= 6.0' do
      xcode_selected = Resources.shared.xcode_select_xcode_hash
      xcode_installs = Resources.shared.alt_xcodes_gte_xc51_hash + [xcode_selected]
      min_version = RunLoop::Version.new('6.0')
      xcode_versions = xcode_installs.delete_if { |hash| hash[:version] < min_version }
      if xcode_versions.empty?
        it 'no Xcode >= 6.0 was found' do
          expect(true).to be == true
        end
      else
        xcode_versions.each do |xcode6|
          describe "Xcode #{xcode6[:version]}" do
            let(:helper) { Calabash::Rspec::ResetAppSandbox::Helper.new }

            it 'can reset the default simulator' do
              ENV['DEVELOPER_DIR'] = xcode6[:path]
              sim_control = RunLoop::SimControl.new
              helper.launch_and_stop_simulator(launcher, sim_control, 'simulator')

              target_simulator = helper.default_simulator_as_device(sim_control)
              udid = target_simulator.udid

              app_bundles = helper.path_to_sim_app_bundles(udid, target_simulator)
              expect(File).to exist(app_bundles)

              installed_apps = helper.installed_apps(udid, target_simulator)
              expect(installed_apps).to include('LPSimpleExample-cal.app')

              launcher.reset_app_sandbox

              containers = helper.path_to_containers(udid, target_simulator)
              expect(File).not_to exist(containers)
            end

            describe 'can reset a simulator if :udid option is passed' do
              helper = Calabash::Rspec::ResetAppSandbox::Helper.new
              sim_control = RunLoop::SimControl.new
              target_simulator = helper.random_core_simulator(sim_control)
              instruments_launch_name = helper.instruments_launch_name(target_simulator)
              udid = target_simulator.udid
              it "#{instruments_launch_name} [#{udid}]" do
                ENV['DEVELOPER_DIR'] = xcode6[:path]
                sim_control = RunLoop::SimControl.new
                helper.launch_and_stop_simulator(launcher, sim_control, instruments_launch_name)

                app_bundles = helper.path_to_sim_app_bundles(udid, target_simulator)
                expect(File).to exist(app_bundles)

                installed_apps = helper.installed_apps(udid, target_simulator)
                expect(installed_apps).to include('LPSimpleExample-cal.app')

                launcher.reset_app_sandbox({:udid => udid})

                containers = helper.path_to_containers(udid, target_simulator)
                expect(File).not_to exist(containers)
              end
            end

            describe 'respects the DEVICE_TARGET env var' do
              helper = Calabash::Rspec::ResetAppSandbox::Helper.new
              sim_control = RunLoop::SimControl.new
              target_simulator = helper.random_core_simulator(sim_control)
              instruments_launch_name = helper.instruments_launch_name(target_simulator)
              udid = target_simulator.udid
              it "#{instruments_launch_name} [#{udid}]" do
                ENV['DEVELOPER_DIR'] = xcode6[:path]
                ENV['DEVICE_TARGET'] = instruments_launch_name
                sim_control = RunLoop::SimControl.new
                helper.launch_and_stop_simulator(launcher, sim_control, instruments_launch_name)

                app_bundles = helper.path_to_sim_app_bundles(udid, target_simulator)
                expect(File).to exist(app_bundles)

                installed_apps = helper.installed_apps(udid, target_simulator)
                expect(installed_apps).to include('LPSimpleExample-cal.app')

                launcher.reset_app_sandbox

                containers = helper.path_to_containers(udid, target_simulator)
                expect(File).not_to exist(containers)
              end
            end
          end
        end
      end
    end
  end
end
