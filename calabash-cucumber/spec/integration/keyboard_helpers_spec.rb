module Calabash
  module Rspec
    module IntegrationTests
      module KeyboardHelpers
        class TestObject
          include Calabash::Cucumber::KeyboardHelpers
          include Calabash::Cucumber::WaitHelpers
          include Calabash::Cucumber::Map
          include Calabash::Cucumber::UIA
        end
      end
    end
  end
end

describe Calabash::Cucumber::KeyboardHelpers do

  let(:keyboard_helper) { Calabash::Rspec::IntegrationTests::KeyboardHelpers::TestObject.new }

  before(:example) {
    RunLoop::SimControl.terminate_all_sims
    options = {
          :app => Resources.shared.app_bundle_path(:lp_simple_example),
          :device_target =>  'simulator',
          :sim_control => RunLoop::SimControl.new,
          :launch_retries => Resources.shared.travis_ci? ? 5 : 2
    }
    launcher = Calabash::Cucumber::Launcher.new
    launcher.relaunch(options)
    keyboard_helper.wait_for_element_exists('textField', :timeout => 8)
    # Set the keyboard to the default - must be set _before_ keyboard is
    # presented.  Required by timeout examples; default keyboard does not have
    # a backquote ` key.
    keyboard_helper.map('textField', :query, [{:setKeyboardType => 0}])
    keyboard_helper.map('textField', :query, [{:setAutocorrectionType => 1}])
    keyboard_helper.uia("uia.tapOffset('{:x 152, :y 101.5}')")
    keyboard_helper.wait_for_keyboard
  }

  describe '#keyboard_enter_text' do
    describe 'optional arguments' do
      it 'passes :timeout to uia_type_string' do
        string = 'There is no ` backquote.'
        before = Time.now
        expect {
          keyboard_helper.keyboard_enter_text(string, :timeout => 5)
        }.to raise_error TimeoutError
        expect(Time.now - before).to be < 6
      end
    end
  end
end
