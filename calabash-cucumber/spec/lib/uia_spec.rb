
describe Calabash::Cucumber::UIA do

  let(:world) do
    Class.new do
      include Calabash::Cucumber::UIA
      include Calabash::Cucumber::HTTPHelpers
      include Calabash::Cucumber::WaitHelpers
      def to_s; "#<World RSPEC STUB>"; end
      def inspect; to_s; end

      # The dread Cucumber embed
      def embed(_, _, _); ; end
    end.new
  end

  context "Disabling UIA in the context of DeviceAgent" do
    let(:uia_path) do
      File.expand_path(File.join("lib", "calabash-cucumber", "uia.rb"))
    end

    let(:xcode) { RunLoop::Xcode.new }
    let(:automator) do
      Class.new(Calabash::Cucumber::Automator::Automator) do
        def to_s; "#<Automator RSPEC STUB>"; end
        def inspect; to_s; end
      end
    end

    context ".rewrite_instance_methods_if_necessary" do
      it "does not rewrite on the XTC" do
        expect(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(true)

        actual = Calabash::Cucumber::UIA.rewrite_instance_methods_if_necessary(xcode, automator)
        expect(actual).to be_falsey
      end

      it "rewrites if Xcode >= 8" do
        expect(xcode).to receive(:version_gte_8?).and_return(true)
        expect(Calabash::Cucumber::UIA).to(
          receive(:rewrite_instance_methods_to_raise).and_return(true)
        )

        actual = Calabash::Cucumber::UIA.rewrite_instance_methods_if_necessary(xcode, automator)
        expect(actual).to be_truthy
      end

      context "Xcode < 8" do

        before do
          expect(xcode).to receive(:version_gte_8?).and_return(false)
        end

        it "does not rewrite if the automator arg is nil" do
          expect(Calabash::Cucumber::UIA).not_to receive(:rewrite_instance_methods_to_raise)

          actual = Calabash::Cucumber::UIA.rewrite_instance_methods_if_necessary(xcode, nil)
          expect(actual).to be_falsey
        end

        it "does not rewrite if the automator is not DeviceAgent" do
          expect(Calabash::Cucumber::UIA).not_to receive(:rewrite_instance_methods_to_raise)
          expect(automator).to receive(:name).and_return(:instruments)

          actual = Calabash::Cucumber::UIA.rewrite_instance_methods_if_necessary(xcode, automator)
          expect(actual).to be_falsey
        end

        it "rewrites if the automator is DeviceAgent" do
          expect(Calabash::Cucumber::UIA).to(
            receive(:rewrite_instance_methods_to_raise).and_return(true)
          )
          expect(automator).to receive(:name).and_return(:device_agent)

          actual = Calabash::Cucumber::UIA.rewrite_instance_methods_if_necessary(xcode, automator)
          expect(actual).to be_truthy
        end
      end
    end

    context ".rewrite_instance_methods_to_raise" do
      let(:reason) { "Why did this raise" }

      it "rewrites all the UIA instance methods to raise" do
        methods = Calabash::Cucumber::UIA.instance_methods

        actual = Calabash::Cucumber::UIA.rewrite_instance_methods_to_raise(reason)
        expect(actual).to be_truthy

        methods.each do |method_name|
          expect do
            world.send(method_name)
          end.to raise_error RuntimeError, /#{reason}/
        end
      end
    end

    after do
      load(uia_path)

      # Test that UIA was reloaded.
      expect(world.escape_uia_string("string")).to be == "string"
    end
  end

  describe 'uia_result' do
    describe "when 'status' key is 'success' returns" do
      it "value of the 'value' key when key exists" do
        value = {:key => :value }
        input = {'status' => 'success', 'value' => value, 'index' =>0}
        expect(world.send(:uia_result, input)).to be == value
      end

      it "empty hash when 'value' key does not exist" do
        input = {'status' => 'success', 'index' =>0}
        expect(world.send(:uia_result, input)).to be == nil
      end
    end

    describe "when 'status' key is not 'success' returns" do
      it 'the argument it was passed' do
        input = {'status' => 'error', 'value' => nil, 'index' =>0}
        expect(world.send(:uia_result, input)).to be == input
      end
    end
  end

  describe 'uia_type_string' do
    describe 'does not raise an error' do
      it "when :status == 'success' and :value is a hash" do
        mocked_value = {}
        expect(world).to receive(:uia_handle_command).and_return(mocked_value)
        expect { world.uia_type_string 'foo' }.not_to raise_error
      end

      it "when :status == 'success' and :value is not a Hash" do
        # Output from typing in UIWebViews.
        mocked_value = ':nil'
        expect(world).to receive(:uia_handle_command).and_return(mocked_value)
        expect { world.uia_type_string 'foo' }.not_to raise_error
      end

      it "when :status != 'success' or 'error'" do
        mocked_value = {'status' => 'unknown', 'value' => 'error message', 'index' =>0}
        expect(world).to receive(:uia_handle_command).and_return(mocked_value)
        expect { world.uia_type_string 'foo' }.not_to raise_error
      end
    end

    describe "raises an error when :status == 'error'" do
      it 'and result has a :value key' do
        mocked_value = {'status' => 'error', 'value' => 'error message', 'index' =>0}
        expect(world).to receive(:uia_handle_command).and_return(mocked_value)
        expect { world.uia_type_string 'foo' }.to raise_error RuntimeError
      end

      it 'and result does not have a :value key' do
        mocked_value = {'status' => 'error', 'index' =>0}
        expect(world).to receive(:uia_handle_command).and_return(mocked_value)
        expect { world.uia_type_string 'foo' }.to raise_error RuntimeError
      end
    end
  end

  context "#uia_keyboard_visible?" do
    it "returns true if UIA window query is != ':nil'" do
      expect(world).to receive(:uia_query_windows).with(:keyboard).and_return("anything by :nil")

      expect(world.uia_keyboard_visible?).to be_truthy
    end

    it "returns false if UIA window query is == ':nil'" do
      expect(world).to receive(:uia_query_windows).with(:keyboard).and_return(":nil")

      expect(world.uia_keyboard_visible?).to be_falsey
    end
  end

  context "#uia_wait_for_keyboard" do
    it "waits for keyboard to appear" do
      expect(world).to receive(:uia_keyboard_visible?).and_return(false, false, true)

      options = { :retry_frequency => 0, :post_timeout => 0.0}
      expect(world.uia_wait_for_keyboard(options)).to be_truthy
    end

    it "raises an error if keyboard does not appear" do
      expect(world).to receive(:uia_keyboard_visible?).at_least(:once).and_return(false)
      expect(world).to receive(:screenshot).and_return(true)
      expect(world).to receive(:embed).and_return(true)

      options = { :retry_frequency => 0, :timeout => 0.05 }
      expect do
        world.uia_wait_for_keyboard(options)
      end.to raise_error Calabash::Cucumber::WaitHelpers::WaitError,
                         /Keyboard did not appear/
    end

    it "merges the options it passes to wait_for" do
      options = {
        :post_timeout => 100,
        :timeout_message => "Alternative message",
        :retry_frequency => 0.1,
        :timeout => 100
      }
      expect(world).to receive(:wait_for).with(options).and_return(true)

      expect(world.uia_wait_for_keyboard(options)).to be_truthy
    end
  end

  describe 'uia' do
    describe ':preferences strategy' do
      describe 'raises an error' do
        it 'when http returns nil - simulates an app crash' do
          launcher = Calabash::Cucumber::Launcher.new
          expect(launcher).to receive(:run_loop).and_return({:uia_strategy => :preferences})
          expect(Calabash::Cucumber::Launcher).to receive(:launcher_if_used).and_return(launcher)
          expect(launcher).to receive(:attached_to_automator?).and_return true
          expect(world).to receive(:http).and_return('')

          expect do
            world.uia('command')
          end.to raise_error RuntimeError
        end
      end
    end

    describe 'host strategy' do
      describe 'raises an error' do
        it 'when response status is not expected' do
          launcher = Calabash::Cucumber::Launcher.new
          expect(launcher).to receive(:run_loop).and_return({:uia_strategy => :host})
          expect(Calabash::Cucumber::Launcher).to receive(:launcher_if_used).and_return(launcher)
          expect(launcher).to receive(:attached_to_automator?).and_return true

          run_loop_response =
                {
                      'status' => 'unknown status',
                      'value' => 'Some value',
                      'index' => 1
                }
          expect(RunLoop).to receive(:send_command).and_return(run_loop_response)

          expect do
            world.uia('command')
          end.to raise_error RuntimeError
        end

        describe 'when response status is error' do
          it 'and response contains a value' do
            launcher = Calabash::Cucumber::Launcher.new
            expect(launcher).to receive(:run_loop).and_return({:uia_strategy => :host})
            expect(Calabash::Cucumber::Launcher).to receive(:launcher_if_used).and_return(launcher)
            expect(launcher).to receive(:attached_to_automator?).and_return true

            run_loop_response =
                  {
                        'status' => 'error',
                        'value' => 'Some value',
                        'index' => 1
                  }
            expect(RunLoop).to receive(:send_command).and_return(run_loop_response)

            expect do
              world.uia('command')
            end.to raise_error RuntimeError
          end

          it 'and response does not contain a value' do
            launcher = Calabash::Cucumber::Launcher.new
            expect(launcher).to receive(:run_loop).and_return({:uia_strategy => :host})
            expect(Calabash::Cucumber::Launcher).to receive(:launcher_if_used).and_return(launcher)
            expect(launcher).to receive(:attached_to_automator?).and_return true

            run_loop_response =
              {
                'status' => 'error',
                'index' => 1
              }
            expect(RunLoop).to receive(:send_command).and_return(run_loop_response)

            expect do
              world.uia('command')
            end.to raise_error('uia action failed for an unknown reason')
          end
        end
      end
    end
  end
end
