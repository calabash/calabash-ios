describe Calabash::Cucumber::WaitHelpers do
  include Calabash::Cucumber::WaitHelpers

  # def handle_error_with_options(ex, timeout_message, screenshot_on_error)
  #   msg = (timeout_message || ex)
  #   if ex
  #     error_class = ex.class
  #   else
  #     error_class = RuntimeError
  #   end
  #   if screenshot_on_error
  #     screenshot_and_raise msg
  #   else
  #     raise error_class, msg
  #   end
  # end

  describe '.handle_error_with_options' do
    describe 'getting the message right' do
      it 'uses timeout_message if available' do
        expect {
          handle_error_with_options(nil, 'timed out!', false)
        }.to raise_error(RuntimeError, 'timed out!')
      end

      it 'uses error message if timeout_message is nil' do
        error = RuntimeError.new('Some other exception')
        expect {
          handle_error_with_options(error, nil, false)
        }.to raise_error(RuntimeError, 'Some other exception')
      end
    end

    describe 'getting the exception class right' do
      it 'uses error class if available' do
        error = ArgumentError.new('An argument error.')
        expect {
          handle_error_with_options(error, nil, false)
        }.to raise_error(ArgumentError, 'An argument error.' )
      end

      it 'raises a Runtime error otherwise' do
        expect {
          handle_error_with_options(nil, 'Generic error', false)
        }.to raise_error(RuntimeError, 'Generic error' )
      end
    end

    describe 'taking a screenshot' do
      it 'takes screenshot if argument is true' do
        timeout_message = 'Generic error'
        expect(self).to receive(:screenshot_and_raise).and_raise(RuntimeError, timeout_message)
        expect {
          handle_error_with_options(nil, timeout_message, true)
        }.to raise_error(RuntimeError, timeout_message )
      end

      # @todo This is probably the wrong behavior for screenshot_and_raise
      it 'always raise RuntimeError' do
        timeout_message = 'An argument error'
        error = ArgumentError.new(timeout_message)
        expect(self).to receive(:screenshot_and_raise).and_raise(RuntimeError, timeout_message)
        expect {
          handle_error_with_options(error, nil, true)
        }.to raise_error(RuntimeError, timeout_message)
      end
    end
  end

  describe '.wait_for_condition' do
    include Calabash::Cucumber::HTTPHelpers
    it 'rescues StandardError' do
      expect(self).to receive(:http).and_raise(StandardError, 'I got raised!')
      expect {
        wait_for_condition({screenshot_on_error: false})
      }.to raise_error(StandardError, 'I got raised!')
    end
  end
end
