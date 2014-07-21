require 'spec_helper'
require 'calabash-cucumber/launcher'
require 'calabash-cucumber/utils/simulator_accessibility'

require 'run_loop'

describe 'Calabash Launcher' do

  SIM_SDK_DIR_REGEX = /(\d)\.(\d)\.?(\d)?(-64)?/
  UDID = '66h3hfgc466836ehcg72738eh8f322842855d2fd'
  IPHONE_4IN_R_64 = 'iPhone Retina (4-inch 64-bit) - Simulator - iOS 7.1'

  before(:each) do
    @launcher = Calabash::Cucumber::Launcher.new
  end

  before(:each) do
    ENV['DEVICE_TARGET'] = nil
    ENV['DETECT_CONNECTED_DEVICE'] = nil
  end

  def set_device_target(val)
    ENV['DEVICE_TARGET'] = val
  end

  describe 'simulator_target? should respond correctly to DEVICE_TARGET' do

    it 'should return true if DEVICE_TARGET is nil' do
      expect(@launcher.simulator_target?).to be == false
    end

    it 'should return true if DEVICE_TARGET is simulator' do
      set_device_target('simulator')
      expect(@launcher.simulator_target?).to be == true
    end

    it 'should return false if DEVICE_TARGET is device' do
      set_device_target('device')
      expect(@launcher.simulator_target?).to be == false
    end

    it 'should return false if DEVICE_TARGET is udid' do
      # noinspection SpellCheckingInspection
      set_device_target(UDID)
      expect(@launcher.simulator_target?).to be == false
    end

    it 'should return true for Xcode 5.1 style simulator names' do
      set_device_target('iPhone Retina (4-inch) - Simulator - iOS 7.1')
      expect(@launcher.simulator_target?).to be == true

      set_device_target('iPhone - Simulator - iOS 6.1')
      expect(@launcher.simulator_target?).to be == true

      set_device_target('iPad Retina (64-bit) - Simulator - iOS 7.0')
      expect(@launcher.simulator_target?).to be == true
    end

    it 'should return true when passed a hash with :device_target => a simulator' do
      hash = {:device_target => 'simulator'}
      expect(@launcher.simulator_target?(hash)).to be == true

      hash = {:device_target => 'iPhone Retina (4-inch) - Simulator - iOS 7.1'}
      expect(@launcher.simulator_target?(hash)).to be == true
    end

    it 'should return false when passed a hash with :device_target != a simulator' do
      hash = {:device_target => 'device'}
      expect(@launcher.simulator_target?(hash)).to be == false

      hash = {:device_target => UDID}
      expect(@launcher.simulator_target?(hash)).to be == false

      hash = {:device_target => 'foobar'}
      expect(@launcher.simulator_target?(hash)).to be == false
    end

    it 'should return false when passed a hash with no :device_target key' do
      hash = {:foobar => 'foobar'}
      expect(@launcher.simulator_target?(hash)).to be == false
    end
  end

  describe 'resetting application content and settings' do

    SANDBOX_DIRS = ['Library', 'Documents', 'tmp']

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

    describe 'should be able to detect the base simulator sdk from the launch args' do
      it 'should return nil if the test targets a device' do
        expect(@launcher).to receive(:device_target?).and_return(true)
        expect(@launcher.sdk_version_for_simulator_target({})).to be nil
      end

      it 'should return nil if :device_target is nil' do
        expect(@launcher.sdk_version_for_simulator_target({})).to be nil
      end

      it 'should return nil if :device_target is not a simulator' do
        launch_args = {:device_target => UDID}
        expect(@launcher.sdk_version_for_simulator_target(launch_args)).to be nil
      end

      it "should return nil if :device_target is 'simulator'" do
        launch_args = {:device_target => 'simulator'}
        expect(@launcher.sdk_version_for_simulator_target(launch_args)).to be nil
      end

      it 'should return an SDK if :device_target is an Xcode 5.1+ simulator string' do
        launch_args = {:device_target => 'iPhone Retina (4-inch 64-bit) - Simulator - iOS 7.0'}
        expect(@launcher.sdk_version_for_simulator_target(launch_args)).to be == '7.0'
      end
    end

    describe 'reset_app_sandbox should reset the application sandbox' do
      it 'should generate a warning if called against a device' do
        expect(@launcher).to receive(:device_target?).and_return(true)
        args = args_for_reset_app_sandbox
        out = capture_stderr do
          @launcher.reset_app_sandbox(args)
        end
        expect(out.string).to be == "\e[34m\nWARN: calling 'reset_app_sandbox' when targeting a device.\e[0m\n"
      end

      it 'should remove the correct items from the sandbox' do
        args = args_for_reset_app_sandbox '7.1'

        # make the expected directories and expect they are there
        app_udid_path = populate_app_sandbox(args[:path])
        directories = Dir.glob("#{app_udid_path}/*").select {|f| File.directory? f }
        expected = ['LPSimpleExample-cal.app'].concat(SANDBOX_DIRS)
        expect(directories.map { |dir| File.basename(dir) }).to match_array(expected)

        # need to mock the output of directories_for_sdk_prefix method by mocking
        # the simulator_app_support_dir method
        mocked_support_dir = File.expand_path(File.join(__FILE__, '..', 'resources/launcher'))
        expect(@launcher).to receive(:simulator_app_support_dir).and_return(mocked_support_dir)

        @launcher.reset_app_sandbox(args)
        directories = Dir.glob("#{app_udid_path}/*").select {|f| File.directory? f }
        expect(directories.map { |dir| File.basename(dir) }).to contain_exactly('LPSimpleExample-cal.app')
      end

      it 'should remove the correct items from _all_ sandboxes when pass :all' do
        support_dir = File.expand_path(File.join(__FILE__, '..', 'resources/launcher'))
        sdks = Dir["#{support_dir}/*"].select { |x| x =~ SIM_SDK_DIR_REGEX }.map { |x| File.basename(x) }
        app_udid_paths = []
        sdks.each do |sdk|
          args = args_for_reset_app_sandbox sdk
          app_udid_path = populate_app_sandbox(args[:path])
          app_udid_paths << app_udid_path
          directories = Dir.glob("#{app_udid_path}/*").select {|f| File.directory? f }
          expected = ['LPSimpleExample-cal.app'].concat(SANDBOX_DIRS)
          expect(directories.map { |dir| File.basename(dir) }).to match_array(expected)
        end

        expect(@launcher).to receive(:simulator_app_support_dir).and_return(support_dir)
        # we need the :path to be set correctly and then we can change to :all
        args = args_for_reset_app_sandbox('7.1')
        args[:sdk ] = :all
        @launcher.reset_app_sandbox(args)
        app_udid_paths.each do |app_udid_path|
          directories = Dir.glob("#{app_udid_path}/*").select {|f| File.directory? f }
          expect(directories.map { |dir| File.basename(dir) }).to contain_exactly('LPSimpleExample-cal.app')
        end
      end
    end
  end

  describe 'reset_simulator' do
    it 'should raise an error if running on a device' do
      ENV['DEVICE_TARGET'] = UDID
      expect {  @launcher.reset_simulator  }.to raise_error(RuntimeError)
    end

    it 'should reset the simulator' do
      @launcher.reset_simulator
    end
  end

  describe 'default launch args should respect DEVICE_TARGET' do

    it "should return 'simulator' if DEVICE_TARGET nil" do
      args = @launcher.default_launch_args
      expect(args[:device_target]).to be == 'simulator'
    end

    describe 'running with instruments' do

      it 'should be running against instruments' do
        args = @launcher.default_launch_args
        expect(args[:launch_method]).to be == :instruments
      end

      describe 'running against devices' do

        describe 'when DEVICE_TARGET = < udid >' do
          before(:each) do
            ENV['DEVICE_TARGET'] = UDID
          end

          it 'it should return udid if DEVICE_TARGET is a udid' do
            args = @launcher.default_launch_args
            expect(args[:device_target]).to be == UDID
            expect(args[:udid]).to be == UDID
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
                args = @launcher.default_launch_args
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

              describe "when DETECT_CONNECTED_DEVICE != '1'" do
                it 'should return a udid if DEVICE_TARGET=device if a device is connected and simulator otherwise' do
                  args = @launcher.default_launch_args
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
          before(:each) do
            ENV['DEVICE_TARGET'] =  IPHONE_4IN_R_64
          end

          it 'should return the correct simulator' do
            args = @launcher.default_launch_args
            expect(args[:device_target]).to be == IPHONE_4IN_R_64
          end

        end

      end
    end
  end
end
