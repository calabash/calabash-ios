require 'calabash-cucumber/launch/simulator_helper'
require 'sim_launcher'
require 'calabash-cucumber/device'
require 'run_loop'


class Calabash::Cucumber::Launcher
  attr_accessor :run_loop
  attr_accessor :device_target
  attr_accessor :device

  class StartError < RuntimeError
    attr_accessor :error
    def initialize(err)
      self.error= err
    end

    def to_s
      "#{super.to_s}: #{error}"
    end
  end

  def self.launcher(device_target=:simulator)
    @@launcher ||= Launcher.new(device_target)
  end

  def self.launcher_if_used
    @@launcher
  end

  def initialize(device_target=:simulator)
    self.device_target = device_target
    @@launcher = self
  end

  class CalabashLauncherTimeoutErr < Timeout::Error
  end

  def calabash_no_stop?
    calabash_no_launch? or ENV['NO_STOP']=="1"
  end

  def calabash_no_launch?
    ENV['NO_LAUNCH']=='1'
  end

  def device_target?
    (ENV['DEVICE_TARGET'] != nil) && (not simulator_target?)
  end

  def simulator_target?
    ENV['DEVICE_TARGET'] == 'simulator'
  end

  def sdk_version
    ENV['SDK_VERSION']
  end

  def reset_between_scenarios?
    ENV['RESET_BETWEEN_SCENARIOS']=="1"
  end

  def device_env
    ENV['DEVICE'] || 'iphone'
  end

  def active?
    (simulator_target? || device_target?) && (not run_loop.nil?)
  end

  def ios_major_version
    return nil if device.nil? or device.ios_version.nil?
    device.ios_major_version
  end

  def ios_version
    return nil if device.nil?
    device.ios_version
  end


  def reset_app_jail(sdk=nil, path=nil)
    return if device_target?

    sdk = sdk || ENV['SDK_VERSION'] || SimLauncher::SdkDetector.new().latest_sdk_version
    path = path || Calabash::Cucumber::SimulatorHelper.app_bundle_or_raise(app_path)

    app = File.basename(path)
    bundle = `find "#{ENV['HOME']}/Library/Application Support/iPhone Simulator/#{sdk}/Applications/" -type d -depth 2 -name "#{app}" | head -n 1`
    return if bundle.empty? # Assuming we're already clean

    sandbox = File.dirname(bundle)
    ['Library', 'Documents', 'tmp'].each do |dir|
      FileUtils.rm_rf(File.join(sandbox, dir))
    end
  end

  def relaunch(args={})
    RunLoop.stop(run_loop) if run_loop

    if device_target?
      default_args = {:app => ENV['BUNDLE_ID']}
      target = ENV['DEVICE_TARGET']
      if target != 'DEVICE'
        default_args[:udid] = target
      end
      default_args
      self.run_loop = new_run_loop(default_args.merge(args))
    else

      sdk = sdk_version || SimLauncher::SdkDetector.new().latest_sdk_version
      path = Calabash::Cucumber::SimulatorHelper.app_bundle_or_raise(app_path)
      if reset_between_scenarios?
        reset_app_jail(sdk, path)
      end

      if simulator_target?
        default_args = {:app => path, :device => device_env.to_sym}
        self.run_loop = new_run_loop(default_args.merge(args))
      else
        ## sim launcher
        Calabash::Cucumber::SimulatorHelper.relaunch(path, sdk, device_env, args)
      end

    end
    ensure_connectivity
  end

  def new_run_loop(args)
    last_err = nil
    3.times do
      begin
        return RunLoop.run(args)
      rescue RunLoop::TimeoutError => e
        if ENV['CALABASH_FULL_CONSOLE_OUTPUT'] == '1'
          puts "retrying run loop..."
        end
      end
    end
    raise StartError.new(last_err)
  end

  def ensure_connectivity
    begin
      max_retry_count = (ENV['MAX_CONNECT_RETRY'] || 10).to_i
      timeout = (ENV['CONNECT_TIMEOUT'] || 30).to_i
      retry_count = 0
      connected = false
      if ENV['CALABASH_FULL_CONSOLE_OUTPUT'] == '1'
        puts "Waiting for App to be ready"
      end
      until connected do
        raise "MAX_RETRIES" if retry_count == max_retry_count
        retry_count += 1
        begin
          Timeout::timeout(timeout, CalabashLauncherTimeoutErr) do
            until connected
              begin
                connected = (ping_app == '200')
                break if connected
              rescue Exception => e
                #p e
                #retry
              ensure
                sleep 1 unless connected
              end
            end
          end
        rescue CalabashLauncherTimeoutErr => e
          puts "Timed out...Retry.."
        end
      end
    rescue RuntimeError => e
      p e
      msg = "Unable to make connection to Calabash Server at #{ENV['DEVICE_ENDPOINT']|| "http://localhost:37265/"}\n"
      msg << "Make sure you don't have a firewall blocking traffic to #{ENV['DEVICE_ENDPOINT']|| "http://localhost:37265/"}.\n"
      raise msg
    end
  end

  def ping_app
    url = URI.parse(ENV['DEVICE_ENDPOINT']|| "http://localhost:37265/")

    http = Net::HTTP.new(url.host, url.port)
    res = http.start do |sess|
      sess.request Net::HTTP::Get.new(ENV['CALABASH_VERSION_PATH'] || "version")
    end
    status = res.code
    begin
      http.finish if http and http.started?
    rescue Exception => e

    end

    if status=='200'
      version_body = JSON.parse(res.body)
      self.device = Calabash::Cucumber::Device.new(url, version_body)
    end

    status
  end

  def stop
    RunLoop.stop(run_loop)
  end

  def app_path
    ENV['APP_BUNDLE_PATH'] || (defined?(APP_BUNDLE_PATH) && APP_BUNDLE_PATH)
  end

  def calabash_notify(world)
    if world.respond_to?(:on_launch)
      world.on_launch
    end
  end
end

