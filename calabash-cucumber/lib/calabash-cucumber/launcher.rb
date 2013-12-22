require 'calabash-cucumber/launch/simulator_helper'
require 'sim_launcher'
require 'calabash-cucumber/device'
require 'calabash-cucumber/actions/instruments_actions'
require 'calabash-cucumber/actions/playback_actions'
require 'run_loop'
require 'cfpropertylist'

class Calabash::Cucumber::Launcher

  KNOWN_PRIVACY_SETTINGS = {:photos => 'kTCCServicePhotos', :calendar => 'kTCCServiceCalendar', :address_book => 'kTCCServiceAddressBook'}

  attr_accessor :run_loop
  attr_accessor :device
  attr_accessor :actions
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


  def actions
    attach if @actions.nil?
    @actions
  end

  def self.attach
    l = launcher
    return l if l && l.active?
    l.attach

  end

  def attach(max_retry=1, timeout=10)
    if calabash_no_launch?
      self.actions= Calabash::Cucumber::PlaybackActions.new
      return
    end

    pids_str = `ps x -o pid,command | grep -v grep | grep "instruments" | awk '{printf "%s,", $1}'`
    pids = pids_str.split(',').map { |pid| pid.to_i }
    pid = pids.first
    rl = {}
    if pid
      rl[:pid] = pid
      self.actions= Calabash::Cucumber::InstrumentsActions.new
    else
      self.actions= Calabash::Cucumber::PlaybackActions.new
    end

    self.run_loop= rl

    ensure_connectivity(max_retry, timeout)

    major = self.device.ios_major_version
    if major.to_i >= 7 && self.actions.is_a?(Calabash::Cucumber::PlaybackActions)
      puts "\n\n WARNING \n\n"
      puts 'Warning Trying to connect to simulator that was not launched by Calabash/instruments.'
      puts 'To fix this you must let Calabash or instruments launch the app'
      puts 'Continuing... query et al will work.'
      puts "\n\n WARNING \n\n"
      puts "Please read: https://github.com/calabash/calabash-ios/wiki/A0-UIAutomation---instruments-problems"
    end


    self
  end

  def self.instruments?
    l = launcher_if_used
    return false unless l
    l.instruments?
  end

  def self.launcher
    @@launcher ||= Calabash::Cucumber::Launcher.new
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
    directories_for_sdk_prefix(sdk).each do |dir|
      bundle = `find "#{dir}/Applications" -type d -depth 2 -name "#{app}" | head -n 1`
      next if bundle.empty? # Assuming we're already clean
      if ENV['DEBUG']=='1'
        puts "Reset app state for #{bundle}"
      end
      sandbox = File.dirname(bundle)
      ['Library', 'Documents', 'tmp'].each do |dir|
        FileUtils.rm_rf(File.join(sandbox, dir))
      end
    end


  end

  def directories_for_sdk_prefix(sdk)
    Dir["#{ENV['HOME']}/Library/Application Support/iPhone Simulator/#{sdk}*"]
  end

  # Call as update_privacy_settings('com.my.app', {:photos => {:allow => true}})
  def update_privacy_settings(bundle_id, opts={})
    if ENV['DEBUG']=='1'
      puts "Update privacy settings #{bundle_id}, #{opts}"
    end
    unless File.exist?(`which sqlite3`.strip)
      raise 'Error: Unable to find sqlite3. The binary sqlite3 must be installed and on path.'
    end
    opts.each do |setting_name, setting_options|

      setting_name = KNOWN_PRIVACY_SETTINGS[setting_name] || setting_name
      allow = setting_options[:allow] == false ? false : true
      sdk = setting_options[:sdk] || SimLauncher::SdkDetector.new().latest_sdk_version

      dirs = directories_for_sdk_prefix(sdk)
      if ENV['DEBUG']=='1'
        puts "About to update privacy setting #{setting_name} for #{bundle_id}, allow: #{allow} in sdk #{sdk}, #{dirs}"
      end

      dirs.each do |dir|
        if ENV['DEBUG']=='1'
          puts "Setting access for #{bundle_id} for permission #{setting_name} to allow: #{allow}"
        end
        path_to_tcc_db = tcc_database_for_sdk_dir(dir)
        unless File.exist?(path_to_tcc_db)
          puts "Warning: No TCC.db in location #{path_to_tcc_db}"
          next
        end
        allowed_as_i = allow ? 1 : 0
        if privacy_setting(dir, bundle_id,setting_name).nil?
          sql = %Q['INSERT INTO access (service, client, client_type, allowed, prompt_count) VALUES ("#{setting_name}","#{bundle_id}",0,#{allowed_as_i},1);']
        else
          sql = %Q['UPDATE access SET allowed=#{allowed_as_i} where client="#{bundle_id}" AND service="#{setting_name}";']
        end

        if ENV['DEBUG']=='1'
          puts "Executing sql #{sql} on #{path_to_tcc_db}"
        end

        unless system(%Q[sqlite3 "#{path_to_tcc_db}" #{sql}]) && privacy_setting(dir,bundle_id,setting_name) == allowed_as_i
          puts "Warning: Error executing sql: #{sql} against #{path_to_tcc_db} (Setting is #{privacy_setting(dir,bundle_id,setting_name)}). Continuing..."
          next
        end
      end
    end

  end

  def tcc_database_for_sdk_dir(dir)
    File.join(dir,'Library', 'TCC', 'TCC.db')
  end

  def privacy_setting(sdk_dir, bundle_id, setting_name)
    setting_name = KNOWN_PRIVACY_SETTINGS[setting_name] || setting_name
    path_to_tcc_db = tcc_database_for_sdk_dir(sdk_dir)
    sql = %Q['SELECT allowed FROM access WHERE client="#{bundle_id}" and service="#{setting_name}";']
    output = `sqlite3 "#{path_to_tcc_db}" #{sql}`.strip

    (output == '0' || output == '1') ? output.to_i : nil
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
      if detect_connected_device? && (device_tgt.nil? || device_tgt.downcase == 'device')
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

  def detect_connected_device?
    if ENV['DETECT_CONNECTED_DEVICE'] == '1'
      return true
    end

    if ENV['BUNDLE_ID'].nil? && ENV['DETECT_CONNECTED_DEVICE'].nil?
      return false
    end
    if ENV['BUNDLE_ID'] && ENV['DETECT_CONNECTED_DEVICE'].nil?
      return true
    end
    if ENV['DETECT_CONNECTED_DEVICE']
      return ENV['DETECT_CONNECTED_DEVICE'] != '0'
    end

    return false
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


    if args[:privacy_settings]
      if args[:device_target]=='simulator'
        update_privacy_settings(args[:bundle_id], args[:privacy_settings])
      else
        #Not supported on device
        puts 'Warning: :privacy_settings not supported on device'
      end
    end

    if run_with_instruments?(args)
      self.run_loop = new_run_loop(args)
      self.actions= Calabash::Cucumber::InstrumentsActions.new
    else
      # run with sim launcher
      sdk = sdk_version || SimLauncher::SdkDetector.new().available_sdk_versions.reverse.find { |x| !x.start_with?('7') }
      path = Calabash::Cucumber::SimulatorHelper.app_bundle_or_raise(app_path)
      self.actions= Calabash::Cucumber::PlaybackActions.new
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
    5.times do
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

  def ensure_connectivity(max_retry=10, timeout=30)
    begin
      max_retry_count = (ENV['MAX_CONNECT_RETRY'] || max_retry).to_i
      timeout = (ENV['CONNECT_TIMEOUT'] || timeout).to_i
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
    RunLoop.stop(run_loop) if run_loop && run_loop[:pid]
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
    args && args[:launch_method] == :instruments
  end

  def active?
    not run_loop.nil?
  end

  def instruments?
    !!(active? && run_loop[:pid])
  end

  def inspect
    msg = ["#{self.class}: Launch Method #{launch_args && launch_args[:launch_method]}"]
    if run_with_instruments?(self.launch_args) && self.run_loop
      msg << "Log file: #{self.run_loop[:log_file]}"
    end
    msg.join("\n")
  end


end

