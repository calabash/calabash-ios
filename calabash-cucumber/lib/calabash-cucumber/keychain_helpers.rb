require 'calabash-cucumber/core'

module Calabash
  module Cucumber
    # KeychainHelpers provide a helpers to access the iOS keychain.
    #
    # == Simulator Note
    #
    # When running on the simulator, the keychain is *not* sandboxed between
    # applications like it is on a real device. These methods will return
    # keychain records from *all* applications on the simulator, which may
    # result in strange behavior if you aren't expecting it.
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

      # Get a list of all account records saved in the iOS keychain. This
      # method returns a list of hashes; its keys are defined by
      # the +SSKeychain+ library; particular keys of note:
      #
      # * +svce+ is the service
      # * +acct+ is the account (often a username)
      # * +cdat+ is the creation date
      # * +mdat+ is the last-modified date
      def keychain_accounts
        _keychain_get
      end

      # Get a list of all account records saved in the iOS keychain,
      # restricted to a single service. See +keychain_accounts+ for a
      # description of the returned array, although for this method all
      # returned hashes will have the same value for +svce+.
      def keychain_accounts_for_service(service)
        _keychain_get(:service => service)
      end

      # Look up the password stored in the keychain for a given service
      # and account.
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

      # Clear all entries in the keychain. *NOTE*: On the simulator, this
      # will clear *all* entries for *all* applications. On a real device,
      # this will clear all entries for just the current application.
      def keychain_clear
        _keychain_post
      end

      # Clear all entries in the keychain restricted to a single service.
      def keychain_clear_accounts_for_service(service)
        _keychain_post(:service => service)
      end

      # Delete a single keychain record for the given service and account
      # pair.
      def keychain_delete_password(service, account)
        _keychain_post(:service => service, :account => account)
      end

      # Set the password for a given service and account pair.
      def keychain_set_password(service, account, password)
        _keychain_post(:service => service, :account => account, :password => password)
      end


    end
  end
end
