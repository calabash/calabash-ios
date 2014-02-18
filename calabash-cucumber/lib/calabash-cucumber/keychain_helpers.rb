require 'calabash-cucumber/core'

module Calabash
  module Cucumber
    module KeychainHelpers

      # sends appropriately-configured +GET+ request to the +keychain+ endpoint
      def _keychain_get(options={})
        res = http({:method => :get, :raw => true, :path => 'keychain'}, options)
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "get keychain with options '#{options}' failed because: #{res['reason']}\n#{res['details']}"
        end

        res['results']
      end

      def keychain_accounts
        _keychain_get
      end

      def keychain_accounts_for_service(service)
        _keychain_get(:service => service)
      end

      def keychain_password(service, account)
        _keychain_get(:service => service, :account => account).first
      end

      # sends appropriately-configured +POST+ request to the +keychain+ endpoint
      def _keychain_post(options={})
        res = http({:method => :post, :path => 'keychain'}, options)
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "post keychain with options '#{options}' failed because: #{res['reason']}\n#{res['details']}"
        end
      end

      def keychain_clear
        _keychain_post
      end

      def keychain_clear_accounts_for_service(service)
        _keychain_post(:service => service)
      end

      def keychain_delete_password(service, account)
        _keychain_post(:service => service, :account => account)
      end

      def keychain_set_password(service, account, password)
        _keychain_post(:service => service, :account => account, :password => password)
      end


    end
  end
end
