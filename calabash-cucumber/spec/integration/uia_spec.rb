require 'timeout'

module Calabash
  module RspecIntegrationTests
    module UIA
      class TestObject
        include Calabash::Cucumber::UIA
        include Calabash::Cucumber::HTTPHelpers
        include Calabash::Cucumber::KeyboardHelpers
        include Calabash::Cucumber::WaitHelpers
        include Calabash::Cucumber::Map
      end
    end
  end
end

describe Calabash::Cucumber::UIA do

  let(:uia) { Calabash::RspecIntegrationTests::UIA::TestObject.new }

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
    uia.wait_for_element_exists('textField', :timeout => 8)
    # Set the keyboard to the default - must be set _before_ keyboard is
    # presented.  Required by timeout examples; default keyboard does not have
    # a backquote ` key.
    uia.map('textField', :query, [{:setKeyboardType => 0}])
    uia.map('textField', :query, [{:setAutocorrectionType => 1}])
    uia.uia("uia.tapOffset('{:x 152, :y 101.5}')")
    uia.wait_for_keyboard
  }

  describe '#uia_type_string' do
    describe 'optional arguments' do
      it 'when there is existing text, it is not over written' do
        existing = 'I am old '
        new = 'and I am new.'
        uia.map('textField', :query, [{'setText' => existing}])
        uia.uia_type_string(new, {:existing_text => existing})
        actual = uia.send(:_text_from_first_responder)
        expect(actual).to be == "#{existing}#{new}"
      end

      describe 'escaping backslashes' do
        it 'will escape backslashes if :escape_backslashes is truthy' do
          string = 'String with \ an escaped backslash.'
          uia.uia_type_string(string, {:escape_backslashes => true})
          actual = uia.send(:_text_from_first_responder)
          expect(actual).to be == string
        end

        it 'will not escape backslashes if :escape_backslashes is not truthy' do
          string = 'String with \ an unescaped backslash'
          uia.uia_type_string(string, {:escape_backslashes => false})
          actual = uia.send(:_text_from_first_responder)
          expect(actual).to be == 'String with. an unescaped backslash'
        end
      end
    end

    it 'will timeout if string cannot be typed' do
      string = 'There is no ` backquote.'
      expect { uia.uia_type_string(string) }.to raise_error(TimeoutError)
    end
  end
end
