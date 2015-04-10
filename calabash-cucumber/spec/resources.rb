require 'singleton'

class Resources

  include Singleton

  def self.shared
    Resources.instance
  end

  def travis_ci?
    @travis_ci ||= ENV['TRAVIS']
  end

  def active_xcode_version
    @active_xcode_version ||= RunLoop::XCTools.new.xcode_version
  end

  def resources_dir
    @resources_dir ||= File.expand_path(File.join(File.dirname(__FILE__), 'resources'))
  end

  def irbrc_path
    @irbrc_path ||= File.expand_path(File.join(File.dirname(__FILE__), '..', 'scripts', '.irbrc'))
  end

  def app_bundle_path(bundle_name)
    case bundle_name
      when :lp_simple_example
        return @lp_cal_app_bundle_path ||= File.join(self.resources_dir, 'LPSimpleExample-cal.app')
      when :smoke
        return @smoke_app_bundle_path ||= File.join(self.resources_dir, 'CalSmoke.app')
      when :calabash_not_linked
        return @calabash_not_linked ||= File.join(self.resources_dir, 'CalNotLinked.app')
      when :server_gem_compatibility
        return @server_gem_compatibility_app_bundle_path ||= File.join(self.resources_dir, 'server-gem-compatibility.app')
      else
        raise "unexpected argument '#{bundle_name}'"
    end
  end

  def ipa_path
    @ipa_path ||= File.expand_path(File.join(resources_dir, 'LPSimpleExample-cal.ipa'))
  end

  def bundle_id
    @bundle_id = 'com.lesspainful.example.LPSimpleExample-cal'
  end

  def xcode_installs
    @alternative_xcode_installs ||= Luffa::Xcode.new.xcode_installs
  end

  def device_for_mocking
    endpoint = 'http://localhost:37265/'
    # noinspection RubyStringKeysInHashInspection
    version_data =
    {
          'outcome' => 'SUCCESS',
          'app_id' => 'com.littlejoysoftware.Briar-cal',
          'simulator_device' => 'iPhone',
          'version' => '0.10.0',
          'app_name' => 'Briar-cal',
          'iphone_app_emulated_on_ipad' => false,
          '4inch' => false,
          'git' => {
                'remote_origin' => 'git@github.com:calabash/calabash-ios-server.git',
                'branch' => 'master',
                'revision' => 'e494e30'
          },
          'screen_dimensions' => {
                'scale' => 2,
                'width' => 640,
                'sample' => 1,
                'height' => 1136
          },
          'app_version' => '1.4.0',
          'iOS_version' => '8.0',
          'system' => 'x86_64',
          'simulator' => ''
    }
    Calabash::Cucumber::Device.new(endpoint, version_data)
  end

  def server_version(device_or_simulator)
    case device_or_simulator
      when :device
        {}
      when :simulator
        {
              'app_version' => '1.0',
              'outcome' => 'SUCCESS',
              'app_id' => 'com.xamarin.CalSmoke-cal',
              'simulator_device' => 'iPhone',
              'version' => '0.11.0',
              'app_name' => 'CalSmoke-cal',
              'iphone_app_emulated_on_ipad' => false,
              '4inch' => true,
              'git' => {
                    'remote_origin' => 'git@github.com:calabash/calabash-ios-server.git',
                    'branch' => 'develop',
                    'revision' => '652b20b'
              },
              'screen_dimensions' => {
                    'scale' => 2,
                    'width' => 640,
                    'sample' => 1,
                    'height' => 1136
              },
              'iOS_version' => '7.1',
              'system' => 'x86_64',
              'simulator' => 'CoreSimulator 110.2 - Device: iPhone 5 - Runtime: iOS 7.1 (11D167) - DeviceType: iPhone 5',
              'form_factor' => 'iphone 4in'
        }
      else
        raise "expected '#{device_or_simulator}' to be one of #{[:simulator, :device]}"
    end
  end

  def ideviceinstaller
    Luffa::IDeviceInstaller.new(ipa_path, bundle_id)
  end

  def physical_devices_for_testing(xcode_tools)
    version = xcode_tools.xcode_version.to_s
    @physical_devices ||= {}

    unless @physical_devices[version]
      @physical_devices[version] = Luffa::IDeviceInstaller.physical_devices_for_testing(xcode_tools)
    end
    @physical_devices[version]
  end
end
