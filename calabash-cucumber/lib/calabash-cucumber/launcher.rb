require 'calabash-cucumber/launch/simulator_helper'
require 'sim_launcher'
require 'calabash-cucumber/device'
require 'run_loop'
require 'cfpropertylist'

class Calabash::Cucumber::Launcher
  attr_accessor :run_loop
  attr_accessor :device
  attr_accessor :launch_args

  @@launcher = nil

  class StartError < RuntimeError
    attr_accessor :error

    def initialize(err)
      self.error= err
    end

    def to_s
      "#{super.to_s}: #{error}"
    end
  end

  class CalabashLauncherTimeoutErr < Timeout::Error
  end

  def self.launcher
    @@launcher ||= Launcher.new
  end

  def self.launcher_if_used
    @@launcher
  end

  def initialize
    @@launcher = self
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
    sdk ||= sdk_version || SimLauncher::SdkDetector.new().latest_sdk_version
    path ||= Calabash::Cucumber::SimulatorHelper.app_bundle_or_raise(app_path)

    app = File.basename(path)
    bundle = `find "#{ENV['HOME']}/Library/Application Support/iPhone Simulator/#{sdk}/Applications/" -type d -depth 2 -name "#{app}" | head -n 1`
    return if bundle.empty? # Assuming we're already clean

    sandbox = File.dirname(bundle)
    ['Library', 'Documents', 'tmp'].each do |dir|
      FileUtils.rm_rf(File.join(sandbox, dir))
    end
  end

  def default_launch_args
    # APP_BUNDLE_PATH
    # BUNDLE_ID
    # APP (unifies APP_BUNDLE_PATH, BUNDLE_ID)
    # DEVICE_TARGET
    # SDK_VERSION
    # RESET_BETWEEN_SCENARIOS
    # DEVICE
    # NO_LAUNCH
    # NO_STOP

    args = {
        :launch_method => default_launch_method,
        :reset => reset_between_scenarios?,
        :bundle_id => ENV['BUNDLE_ID'],
        :device => device_env,
        :no_stop => calabash_no_stop?,
        :no_launch => calabash_no_launch?,
        :sdk_version => sdk_version
    }

    #:device_target will be set

    if run_with_instruments?(args) && !simulator_target?
      device_tgt = ENV['DEVICE_TARGET']
      if device_tgt.nil? || device_tgt.downcase == 'device'
        device_tgt = RunLoop::Core.detect_connected_device
      end

      if device_tgt
        args[:device_target] = args[:udid] = device_tgt
      else
        args[:device_target] = 'simulator'
      end
    else
      args[:device_target] = 'simulator'
    end


    args
  end

  def default_launch_method
    return :instruments unless sdk_version || use_instruments_env?
    return :instruments if sdk_version.start_with?('7') # Only instruments supported for iOS7+
    sim_detector = SimLauncher::SdkDetector.new()
    available = sim_detector.available_sdk_versions.reject { |v| v.start_with?('7') }
    if available.include?(sdk_version)
      :sim_launcher
    else
      :instruments
    end
  end

  def relaunch(args={})
    RunLoop.stop(run_loop) if run_loop

    args = default_launch_args.merge(args)

    args[:app] = args[:app] || args[:bundle_id] || app_path || detect_app_bundle_from_args(args)


    if args[:app]
      if File.directory?(args[:app])
        args[:app] = File.expand_path(args[:app])
      else
        # args[:app] is not a directory so must be a bundle id
        if args[:device_target] == 'simulator' ## bundle id set, but simulator target
          args[:app] = app_path || detect_app_bundle_from_args(args)
        end
      end
    end

    unless args[:app]
      if args[:device_target]=='simulator'
        device_xamarin_build_dir = 'iPhoneSimulator'
      else
        device_xamarin_build_dir = 'iPhone'
      end
      args[:app] = Calabash::Cucumber::SimulatorHelper.app_bundle_or_raise(app_path, device_xamarin_build_dir)
    end

    args[:bundle_id] ||= detect_bundle_id_from_app_bundle(args)

    args[:device] ||= detect_device_from_args(args)


    reset_app_jail if args[:reset]

    if run_with_instruments?(args)
      self.run_loop = new_run_loop(args)
    else
      # run with sim launcher
      sdk = sdk_version || SimLauncher::SdkDetector.new().available_sdk_versions.reverse.find { |x| !x.start_with?('7') }
      path = Calabash::Cucumber::SimulatorHelper.app_bundle_or_raise(app_path)
      Calabash::Cucumber::SimulatorHelper.relaunch(path, sdk, args[:device].to_s, args)
    end
    self.launch_args = args
    ensure_connectivity
  end

  def detect_device_from_args(args)
    if args[:app] && File.directory?(args[:app])
      # Derive bundle id from bundle_dir
      plist_as_hash = info_plist_from_bundle_path(args[:app])
      if plist_as_hash
        device_family = plist_as_hash['UIDeviceFamily']
        if device_family
          first_device = device_family.first
          if first_device == 2
            return 'ipad'
          else
            return 'iphone'
          end
        end
      end
    else
      args[:app]
    end


  end

  def detect_app_bundle_from_args(args)
    if args[:device_target]=='simulator'
      device_xamarin_build_dir = 'iPhoneSimulator'
    else
      device_xamarin_build_dir = 'iPhone'
    end
    Calabash::Cucumber::SimulatorHelper.detect_app_bundle(nil, device_xamarin_build_dir)
  end

  def detect_bundle_id_from_app_bundle(args)
    if args[:app] && File.directory?(args[:app])
      # Derive bundle id from bundle_dir
      plist_as_hash = info_plist_from_bundle_path(args[:app])
      if plist_as_hash
        plist_as_hash['CFBundleIdentifier']
      end
    else
      args[:app]
    end
  end

  def info_plist_from_bundle_path(bundle_path)
    plist_path = File.join(bundle_path, 'Info.plist')
    info_plist_as_hash(plist_path) if File.exist?(plist_path)
  end

  def new_run_loop(args)
    last_err = nil
    3.times do
      begin
        return RunLoop.run(args)
      rescue RunLoop::TimeoutError => e
        last_err = e
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

    if status == '200'
      version_body = JSON.parse(res.body)
      self.device = Calabash::Cucumber::Device.new(url, version_body)
    end

    status
  end

  def stop
    RunLoop.stop(run_loop)
  end

  def calabash_notify(world)
    if world.respond_to?(:on_launch)
      world.on_launch
    end
  end


  def info_plist_as_hash(plist_path)
    unless File.exist?(plist_path)
      raise "Unable to find Info.plist: #{plist_path}"
    end
    parsedplist = CFPropertyList::List.new(:file => plist_path)
    CFPropertyList.native_types(parsedplist.value)
  end

  def detect_bundle_id
    begin
      bundle_path = Calabash::Cucumber::SimulatorHelper.app_bundle_or_raise(app_path)
      plist_path = File.join(bundle_path, 'Info.plist')
      info_plist_as_hash(plist_path)['CFBundleIdentifier']
    rescue => e
      raise "Unable to automatically find bundle id. Please set BUNDLE_ID environment variable. #{e}"
    end
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

  def use_instruments_env?
    ENV['LAUNCH_VIA'] == 'instruments'
  end

  def reset_between_scenarios?
    ENV['RESET_BETWEEN_SCENARIOS']=="1"
  end

  def device_env
    ENV['DEVICE']
  end

  def app_path
    ENV['APP_BUNDLE_PATH'] || (defined?(APP_BUNDLE_PATH) && APP_BUNDLE_PATH) || ENV['APP']
  end

  def run_with_instruments?(args)
    args[:launch_method] == :instruments
  end

  def active?
    not run_loop.nil?
  end

  def inspect
    msg = ["#{self.class}: Launch Method #{launch_args[:launch_method]}"]
    if run_with_instruments?(self.launch_args) && self.run_loop
      msg << "Log file: #{self.run_loop[:log_file]}"
    end
    msg.join("\n")
  end


end

