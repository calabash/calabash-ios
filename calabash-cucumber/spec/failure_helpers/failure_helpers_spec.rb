require 'calabash-cucumber/failure_helpers'
require 'calabash-cucumber/http_helpers'

include Calabash::Cucumber::HTTPHelpers
include Calabash::Cucumber::FailureHelpers


describe Calabash::Cucumber::FailureHelpers do
  before(:each) { ENV.delete('SCREENSHOT_PATH') }

  describe '#screenshot' do
    describe 'when SCREENSHOT_PATH is defined and' do
      describe 'the indicated directory exists' do
        it 'saves a screenshot to correct directory' do
          dir_path = File.expand_path(File.join(File.dirname(__FILE__), 'screenshots'))
          FileUtils.mkdir_p dir_path
          expected_filename = File.join(dir_path, 'screenshot_0.png')
          ENV['SCREENSHOT_PATH'] = File.expand_path(File.join(File.dirname(__FILE__), 'screenshots'))
          begin
            expect(self).to receive(:http).and_return('foo')
            actual_filename = screenshot
            expect(actual_filename).to be == expected_filename
          ensure
            FileUtils.rm_rf dir_path
          end
        end
      end

      describe 'the indicated directory does not exist' do
        it 'should raise an error' do
          dir_path = File.expand_path(File.join(File.dirname(__FILE__), 'screenshots'))
          begin
            ENV['SCREENSHOT_PATH'] = File.expand_path(File.join(File.dirname(__FILE__), 'screenshots'))
            expect(self).to receive(:http).and_return('foo')
            expect { screenshot }.to raise_error
          ensure
            FileUtils.rm_rf dir_path
          end
        end
      end
    end
  end
end