require 'calabash-cucumber/launch/simulator_helper'
require 'sim_launcher'
require 'run_loop'


class Calabash::Cucumber::Launcher
  attr_accessor :run_loop
  attr_accessor :device_target

  def initialize(device_target=:simulator)
    self.device_target = device_target
  end

  class CalabashLauncherTimeoutErr < Timeout::Error
  end

  def calabash_no_stop?
    ENV['NO_LAUNCH']=="1" or ENV['NO_STOP']=="1"
  end

  def device_target?
    ENV['DEVICE_TARGET'] == 'device'
  end

  def simulator_target?
    ENV['DEVICE_TARGET'] == 'simulator'
  end

  def active?
    (simulator_target? || device_target?) && (not run_loop.nil?)
  end


  def reset_app_jail(sdk, app_path)
    return if device_target?

    app = File.basename(app_path)
    bundle = `find "#{ENV['HOME']}/Library/Application Support/iPhone Simulator/#{sdk}/Applications/" -type d -depth 2 -name "#{app}" | head -n 1`
    return if bundle.empty? # Assuming we're already clean

    sandbox = File.dirname(bundle)
    ['Library', 'Documents', 'tmp'].each do |dir|
      FileUtils.rm_rf(File.join(sandbox, dir))
    end
  end

  def relaunch(args=nil)
    if run_loop
      RunLoop.stop(run_loop)
    end
    if device_target?
      self.run_loop = RunLoop.run(:app => ENV['BUNDLE_ID'])
    else
      sdk = ENV['SDK_VERSION'] || SimLauncher::SdkDetector.new().latest_sdk_version
      path = Calabash::Cucumber::SimulatorHelper.app_bundle_or_raise(app_path)
      if ENV['RESET_BETWEEN_SCENARIOS']=="1"
        reset_app_jail(sdk, path)
      end

      if simulator_target?
        device = (ENV['DEVICE'] || 'iphone').to_sym
        self.run_loop = RunLoop.run(:app => path, :device => device)
      else
        ## sim launcher
        Calabash::Cucumber::SimulatorHelper.relaunch(path, sdk, ENV['DEVICE'] || 'iphone', args)
      end

    end
    ensure_connectivity

  end

  def ensure_connectivity
    begin
      max_retry_count = (ENV['MAX_CONNECT_RETRY'] || 10).to_i
      timeout = (ENV['CONNECT_TIMEOUT'] || 30).to_i
      retry_count = 0
      connected = false
      puts "Waiting for App to be ready"
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
    rescue e
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
      sess.request Net::HTTP::Get.new "version"
    end
    status = res.code
    begin
      http.finish if http and http.started?
    rescue Exception => e

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
