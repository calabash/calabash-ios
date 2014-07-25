# stubs for documentation
require 'calabash-cucumber/core'
require 'calabash-cucumber/operations'
require 'calabash-cucumber/launcher'

# base module for Frank-Calabash
module Calabash
  module Cucumber
    module Map
      def raw_map(query, method_name, *method_args)
        operation_map = {
            :method_name => method_name,
            :arguments => method_args
        }
        res = http({:method => :post, :path => 'cal_map'},
                   {:query => query, :operation => operation_map})
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "map #{query}, #{method_name} failed because: #{res['reason']}\n#{res['details']}"
        end

        res
      end

    end
  end
end

module Frank
  module Calabash
    def launch(options={})
      launcher = ::Calabash::Cucumber::Launcher.launcher
      #noinspection RubyResolve
      options[:app] ||= File.expand_path('Frank/frankified_build/Frankified.app')
      ::Frank::Cucumber::FrankHelper.selector_engine = 'calabash_uispec'

      launcher.relaunch(options)
    end

    def calabash_client
      Client.new
    end

    module Operations
      include ::Calabash::Cucumber::Operations
    end

    class Client
      include Operations
    end

  end
end
