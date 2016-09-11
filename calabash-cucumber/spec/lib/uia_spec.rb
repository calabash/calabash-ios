
describe Calabash::Cucumber::UIA do

  let(:world) do
    Class.new do
      include Calabash::Cucumber::UIA
      include Calabash::Cucumber::HTTPHelpers
      include Calabash::Cucumber::WaitHelpers
      def to_s; "#<World RSPEC STUB>"; end
      def inspect; to_s; end
    end.new
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
