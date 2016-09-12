# stubs for documentation
require 'calabash-cucumber/core'
require 'calabash-cucumber/operations'
require 'calabash-cucumber/launcher'

# @!visibility private
module Calabash
  module Cucumber
    module Map
      # @!visibility private
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

# @!visibility private
module Frank
  # @!visibility private
  module Calabash
    # @!visibility private
    def launch(options={})
      launcher = ::Calabash::Cucumber::Launcher.launcher
      #noinspection RubyResolve
      options[:app] ||= File.expand_path('Frank/frankified_build/Frankified.app')
      ::Frank::Cucumber::FrankHelper.selector_engine = 'calabash_uispec'

      launcher.relaunch(options)
    end

    # @!visibility private
    def calabash_client
      Client.new
    end

    # @!visibility private
    module Operations
      include ::Calabash::Cucumber::Operations
    end

    # @!visibility private
    class Client
      include Operations
    end
  end
end
