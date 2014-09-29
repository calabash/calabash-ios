require 'singleton'

class Resources

  include Singleton

  def self.shared
    Resources.instance
  end

  def travis_ci?
    @travis_ci ||= ENV['TRAVIS'].to_s == 'true'
  end

  def resources_dir
    @resources_dir = File.expand_path(File.join(File.dirname(__FILE__),  'resources'))
  end

  def app_bundle_path(bundle_name)
    case bundle_name
      when :lp_simple_example
        return @lp_cal_app_bundle_path ||= File.join(self.resources_dir, 'enable-accessibility', 'LPSimpleExample-cal.app')
      when :chou
        return @chou_app_bundle_path ||= File.join(self.resources_dir, 'chou.app')
      else
        raise "unexpected argument '#{bundle_name}'"
    end
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
          'app_version' => '1.4.0',
          'iOS_version' => '8.0',
          'system' => 'x86_64',
          'simulator' => ''
    }
    Calabash::Cucumber::Device.new(endpoint, version_data)
  end
end
