describe Calabash::Cucumber::HTTPHelpers do
  include Calabash::Cucumber::HTTPHelpers

  describe '.make_http_request' do
    it 'rescues StandardError' do
      expect(self).to receive(:init_request).and_raise(StandardError, "I'll raise you 100")
      expect {
        make_http_request({})
      }.to raise_error(StandardError, "I'll raise you 100")
    end
  end
end
