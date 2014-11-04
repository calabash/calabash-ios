require 'calabash-cucumber/utils/plist_buddy'

include Calabash::Cucumber::PlistBuddy

describe '.plist editing' do

  describe 'plist_buddy method' do
    it 'should return the path to the plist_buddy binary' do
      expect(plist_buddy).to be == '/usr/libexec/PlistBuddy'
    end
  end

  describe 'build_plist_cmd' do

    TEMPLATE_PLIST = File.expand_path('./spec/resources/plist_buddy/com.example.plist')
    TESTING_PLIST = File.expand_path('./spec/resources/plist_buddy/com.testing.plist')

    before(:each) do
      FileUtils.rm(TESTING_PLIST) if File.exist?(TESTING_PLIST)
      FileUtils.cp(TEMPLATE_PLIST, TESTING_PLIST)
    end

    describe 'raises errors' do

      it 'should raise error if file does not exist' do
        expect {  build_plist_cmd(:foo, nil, '/path/does/not/exist') }.to raise_error(RuntimeError)
      end

      it 'should raise error if command is not valid' do
        expect { build_plist_cmd(:foo, nil, TESTING_PLIST) }.to raise_error(ArgumentError)
      end

      it 'should raise error if args_hash is missing required key/value pairs' do
        expect { build_plist_cmd(:print, {:foo => 'bar'}, TESTING_PLIST) }.to raise_error(ArgumentError)
      end

    end

    describe 'composing commands' do

      it 'should compose print commands' do
        cmd = build_plist_cmd(:print, {:key => 'foo'}, TESTING_PLIST)
        expect(cmd).to be == "/usr/libexec/PlistBuddy -c \"Print :foo\" \"#{TESTING_PLIST}\""
      end

      it 'should compose set commands' do
        cmd =  build_plist_cmd(:set, {:key => 'foo', :value => 'bar'}, TESTING_PLIST)
        expect(cmd).to be == "/usr/libexec/PlistBuddy -c \"Set :foo bar\" \"#{TESTING_PLIST}\""
      end

      it 'should compose add commands' do
        cmd = build_plist_cmd(:add, {:key => 'foo', :value => 'bar', :type => 'bool'}, TESTING_PLIST)
        expect(cmd).to be == "/usr/libexec/PlistBuddy -c \"Add :foo bool bar\" \"#{TESTING_PLIST}\""
      end

    end

    describe 'reading properties' do

      VERBOSE = {:verbose => true}
      QUIET = {:verbose => false}

      hash =
            {

                  :access_enabled => 'AccessibilityEnabled',
                  :app_access_enabled => 'ApplicationAccessibilityEnabled',
                  :automation_enabled => 'AutomationEnabled',
                  :inspector_showing => 'AXInspectorEnabled',
                  :inspector_full_size => 'AXInspector.enabled',
                  :inspector_frame => 'AXInspector.frame'
            }

      it 'should read properties' do
        res = plist_read(hash[:inspector_showing], TESTING_PLIST, QUIET)
        expect(res).to be == 'false'

        res = plist_read('FOO', TESTING_PLIST, QUIET)
        expect(res).to be == nil
      end

      it 'should set existing properties' do
        res = plist_set(hash[:inspector_showing], 'bool', 'true', TESTING_PLIST, QUIET)
        expect(res).to be == true

        res = plist_read(hash[:inspector_showing], TESTING_PLIST, QUIET)
        expect(res).to be == 'true'
      end

      it 'should add new properties' do
        res = plist_set('FOO', 'bool', 'true', TESTING_PLIST, QUIET)
        expect(res).to be == true

        res = plist_read('FOO', TESTING_PLIST, QUIET)
        expect(res).to be == 'true'
      end
    end
  end
end
