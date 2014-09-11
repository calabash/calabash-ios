require 'calabash-cucumber'

describe Calabash::Cucumber::WaitHelpers do

  describe 'overriding DEFAULT_OPTS' do
    it '.self.override_default_option' do
      new_timeout = 10.0
      Calabash::Cucumber::WaitHelpers.override_default_option(:timeout, new_timeout)
      expect(Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS[:timeout]).to be == new_timeout
    end
  end
end
