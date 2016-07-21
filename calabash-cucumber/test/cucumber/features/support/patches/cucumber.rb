# override cucumber pending on the XTC
if ENV['XAMARIN_TEST_CLOUD'] == '1'
  module Cucumber
    module RbSupport
      def pending(message = 'TODO')
        raise "PENDING: #{message}"
      end

      def ask(message, _)
        raise "Cannot ask: '#{message}'; User interaction is not allowed on the XTC"
      end
    end
  end
  World(Cucumber::RbSupport)
end
