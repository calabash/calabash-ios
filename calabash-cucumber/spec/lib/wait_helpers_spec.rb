describe Calabash::Cucumber::WaitHelpers do

  let(:world) do
    Class.new do
      include Calabash::Cucumber::Core
      include Calabash::Cucumber::WaitHelpers
      include Calabash::Cucumber::HTTPHelpers
    end.new
  end

  describe '.handle_error_with_options' do
    describe 'getting the message right' do
      it 'uses timeout_message if available' do
        expect {
          world.handle_error_with_options(nil, 'timed out!', false)
        }.to raise_error(RuntimeError, 'timed out!')
      end

      it 'uses error message if timeout_message is nil' do
        error = RuntimeError.new('Some other error')
        expect {
          world.handle_error_with_options(error, nil, false)
        }.to raise_error(RuntimeError, 'Some other error')
      end
    end

    describe 'getting the error class right' do
      it 'uses error class if available' do
        error = ArgumentError.new('An argument error.')
        expect {
          world.handle_error_with_options(error, nil, false)
        }.to raise_error(ArgumentError, 'An argument error.' )
      end

      it 'raises a Runtime error otherwise' do
        expect {
          world.handle_error_with_options(nil, 'Generic error', false)
        }.to raise_error(RuntimeError, 'Generic error' )
      end
    end

    describe 'taking a screenshot' do
      it 'takes screenshot if argument is true' do
        timeout_message = 'Generic error'
        expect(world).to receive(:screenshot_and_raise).and_raise(RuntimeError, timeout_message)
        expect {
          world.handle_error_with_options(nil, timeout_message, true)
        }.to raise_error(RuntimeError, timeout_message )
      end

      # @todo This is probably the wrong behavior for screenshot_and_raise
      it 'always raise RuntimeError' do
        timeout_message = 'An argument error'
        error = ArgumentError.new(timeout_message)
        expect(world).to receive(:screenshot_and_raise).and_raise(RuntimeError, timeout_message)
        expect {
          world.handle_error_with_options(error, nil, true)
        }.to raise_error(RuntimeError, timeout_message)
      end
    end
  end

  describe '.wait_for_condition' do
    it 'rescues StandardError' do
      expect(world).to receive(:http).and_raise(StandardError, 'I got raised!')
      expect {
        world.wait_for_condition({screenshot_on_error: false})
      }.to raise_error(StandardError, 'I got raised!')
    end
  end

  it ".wait_tap" do
    query = "my query"
    options = {:tap => :options}
    expect(world).to receive(:wait_for_none_animating).and_return true
    expect(world).to receive(:wait_for_element_exists).with(query, options).and_return true
    expect(world).to receive(:touch).with(query, options).and_return true

    expect(world.wait_tap(query, options)).to be == true
  end
end
