require 'singleton'

class Resources

  include Singleton

  def self.shared
    Resources.instance
  end

  def travis_ci?
    @travis_ci ||= ENV['TRAVIS']
  end

  def current_xcode_version
    @current_xcode_version ||= lambda {
      ENV.delete('DEVELOPER_DIR')
      RunLoop::XCTools.new.xcode_version
    }.call
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

  def ipa_path
    @ipa_path ||= File.expand_path(File.join(resources_dir, 'LPSimpleExample-cal.ipa'))
  end

  def bundle_id
    @bundle_id = 'com.lesspainful.example.LPSimpleExample-cal'
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
              'app_id' => 'com.xamarin.chou-cal',
              'simulator_device' => 'iPhone',
              'version' => '0.11.0',
              'app_name' => 'chou-cal',
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
              'simulator' => 'CoreSimulator 110.2 - Device: iPhone 5 - Runtime: iOS 7.1 (11D167) - DeviceType: iPhone 5'
        }
      else
        raise "expected '#{device_or_simulator}' to be one of #{[:simulator, :device]}"
    end
  end

  def alt_xcode_install_paths
    @alt_xcode_install_paths ||= lambda {
      min_xcode_version = RunLoop::Version.new('5.1')
      Dir.glob('/Xcode/*/*.app/Contents/Developer').map do |path|
        xcode_version = path[/(\d\.\d(\.\d)?)/, 0]
        if RunLoop::Version.new(xcode_version) >= min_xcode_version
          path
        else
          nil
        end
      end
    }.call.compact
  end

  def xcode_select_xcode_hash
    @xcode_select_xcode_hash ||= lambda {
      ENV.delete('DEVELOPER_DIR')
      xcode_tools = RunLoop::XCTools.new
      {:path => xcode_tools.xcode_developer_dir,
       :version => xcode_tools.xcode_version}
    }.call
  end

  def alt_xcode_details_hash
    @alt_xcodes_gte_xc51_hash ||= lambda {
      ENV.delete('DEVELOPER_DIR')
      xcode_select_path = RunLoop::XCTools.new.xcode_developer_dir
      paths =  alt_xcode_install_paths
      paths.map do |path|
        begin
          ENV['DEVELOPER_DIR'] = path
          version = RunLoop::XCTools.new.xcode_version
          if path == xcode_select_path
            nil
          elsif version >= RunLoop::Version.new('5.1')
            {
                  :version => RunLoop::XCTools.new.xcode_version,
                  :path => path
            }
          else
            nil
          end
        ensure
          ENV.delete('DEVELOPER_DIR')
        end
      end
    }.call.compact
  end

  def ideviceinstaller_bin_path
    @ideviceinstaller_bin_path ||= `which ideviceinstaller`.chomp!
  end

  def ideviceinstaller_available?
    path = ideviceinstaller_bin_path
    path and File.exist? ideviceinstaller_bin_path
  end

  def ideviceinstaller(device_udid, cmd, opts={})
    default_opts = {:ipa => ipa_path,
                    :bundle_id => bundle_id}

    merged = default_opts.merge(opts)


    bin_path = ideviceinstaller_bin_path
    bundle_id = merged[:bundle_id]

    case cmd
      when :install
        ipa = merged[:ipa]
        Retriable.retriable do
          uninstall device_udid, bundle_id, bin_path
        end
        Retriable.retriable do
          install device_udid, ipa, bundle_id, bin_path
        end
      when :uninstall
        Retriable.retriable do
          uninstall device_udid, bundle_id, bin_path
        end
      else
        cmds = [:install, :uninstall]
        raise ArgumentError, "expected '#{cmd}' to be one of '#{cmds}'"
    end
  end

  def bundle_installed?(udid, bundle_id, installer)
    cmd = "#{installer} -u #{udid} -l"
    if ENV['DEBUG_UNIX_CALLS'] == '1'
      puts "\033[36mEXEC: #{cmd}\033[0m"
    end
    Open3.popen3(cmd) do  |_, stdout,  stderr, _|
      out = stdout.read.strip
      err = stderr.read.strip
      if ENV['DEBUG_UNIX_CALLS'] == '1'
        puts "#{cmd} => stdout: '#{out}' | stderr: '#{err}'"
      end
      out.strip.split(/\s/).include? bundle_id
    end
  end

  def install(udid, ipa, bundle_id, installer)
    if bundle_installed? udid, bundle_id, installer
      if ENV['DEBUG_UNIX_CALLS'] == '1'
        puts "\033[32mINFO: bundle '#{bundle_id}' is already installed\033[0m"
      end
      return true
    end
    cmd = "#{installer} -u #{udid} --install #{ipa}"
    if ENV['DEBUG_UNIX_CALLS'] == '1'
      puts "\033[36mEXEC: #{cmd}\033[0m"
    end
    Open3.popen3(cmd) do  |_, stdout,  stderr, _|
      out = stdout.read.strip
      err = stderr.read.strip
      if ENV['DEBUG_UNIX_CALLS'] == '1'
        puts "#{cmd} => stdout: '#{out}' | stderr: '#{err}'"
      end
    end
    unless bundle_installed?(udid, bundle_id, installer)
      raise "could not install '#{ipa}' on '#{udid}' with '#{bundle_id}'"
    end
    true
  end

  def uninstall(udid, bundle_id, installer)
    unless bundle_installed? udid, bundle_id, installer
      return true
    end
    cmd = "#{installer} -u #{udid} --uninstall #{bundle_id}"
    if ENV['DEBUG_UNIX_CALLS'] == '1'
      puts "\033[36mEXEC: #{cmd}\033[0m"
    end
    Open3.popen3(cmd) do  |_, stdout,  stderr, _|
      out = stdout.read.strip
      err = stderr.read.strip
      if ENV['DEBUG_UNIX_CALLS'] == '1'
        puts "#{cmd} => stdout: '#{out}' | stderr: '#{err}'"
      end
    end
    if bundle_installed?(udid, bundle_id, installer)
      raise "could not uninstall '#{bundle_id}' on '#{udid}'"
    end
    true
  end
end
