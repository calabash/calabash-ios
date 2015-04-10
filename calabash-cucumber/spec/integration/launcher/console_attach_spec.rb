describe 'Launcher:  #console_attach' do

  describe '#attach' do

    let(:launcher) { Calabash::Cucumber::Launcher.new }
    let(:other_launcher) { Calabash::Cucumber::Launcher.new }

    let(:sim_control) {
      obj = RunLoop::SimControl.new
      obj.reset_sim_content_and_settings
      obj
    }
    let(:launch_options) {
      {
            :app => Resources.shared.app_bundle_path(:lp_simple_example),
            :device_target => 'simulator',
            :no_stop => true,
            :sim_control => sim_control,
            :launch_retries => Luffa::Retry.instance.launch_retries
      }
    }

    def calabash_console_with_strategy(strategy=nil)
      if strategy.nil?
        attach_cmd = 'console_attach'
      else
        attach_cmd = "console_attach(:#{strategy})"
      end

      # :host strategy is hard to automate.
      #
      # The touch causes the app to go into an infinite loop trying to touch
      # the text field.  Manual testing works fine.  Thinking this was race
      # condition on the RunLoop::HostCache, I tried sleeping before the
      # console attach and before the touch; same results - indefinite hanging.
      #
      # Opening a console in a Terminal against the app allows the touch after:
      #
      # > console_attach(:host)
      #
      # I also tried a Timeout.timeout(10), but the timeout was never reached;
      # the popen3 is blocking.
      #
      # The best we can do is to check that the HostCache was read correctly.
      #
      # My best guess is that this has something to do with either:
      # 1. NSLog output crippling UIAutomation.
      # 2. The run_loop repl pipe is somehow blocking.
      Open3.popen3('bundle', *['exec', 'calabash-ios', 'console']) do |stdin, stdout, stderr, _|
        stdin.puts "launcher = #{attach_cmd}"
        if strategy == :host
          stdin.puts "raise 'Launcher is nil' if launcher.nil?"
          stdin.puts "raise 'Launcher run_loop is nil' if launcher.run_loop.nil?"
          stdin.puts "raise 'Launcher pid is nil' if launcher.run_loop[:pid].nil?"
          stdin.puts "raise 'Launcher index is not 1' if launcher.run_loop[:index] != 1"
        else
          stdin.puts "touch 'textField'"
        end
        stdin.close
        yield stdout, stderr
      end
    end

    describe 'can connect to launched apps' do

      before(:each) { FileUtils.rm_rf(RunLoop::HostCache.default_directory) }

      if Luffa::Environment.travis_ci?
        # :host is failing on Travis ~ 33% of the time.
        puts puts "\033[31mWARN: skipping :host on Travis CI - fails 33% of the time.\033[0m"
        strategies = [:preferences, :shared_element]
      else
        strategies = [:preferences, :host, :shared_element]
      end
      strategies.each do |strategy|
        it strategy do

          launch_options[:uia_strategy] = strategy

          launcher.relaunch(launch_options)
          expect(launcher.run_loop).not_to be == nil

          other_launcher.attach({:uia_strategy => strategy})

          expect(other_launcher.run_loop).not_to be nil
          expect(other_launcher.run_loop[:uia_strategy]).to be == strategy

          calabash_console_with_strategy(strategy) do |stdout, stderr|
            expect(stdout.read.strip[/Error/,0]).to be == nil
            expect(stderr.read.strip).to be == ''
          end
        end
      end
    end
  end
end
