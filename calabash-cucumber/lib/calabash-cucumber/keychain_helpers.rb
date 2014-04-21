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
    #
    # @see http://goo.gl/JrFJMM Details about why some operations report
    #   +FAILURE+ and what can be done on the client side mitigate
    #
    # @see https://github.com/soffes/sskeychain SSKeychain
    module KeychainHelpers


      # sends appropriately-configured +GET+ request to the +keychain+ server
      # endpoint.  do not call this function directly; use one of the helper
      # functions provided.
      #
      # @see keychain_accounts
      # @see keychain_account_for_service
      # @return [Array<Hash>] contents of the iOS keychain
      # @param [Hash] options
      # @raise [RuntimeError] if http request does not report success
      def _keychain_get(options={})
        res = http({:method => :get, :raw => true, :path => 'keychain'}, options)
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          raise "get keychain with options '#{options}' failed because: '#{res['reason']}'\n'#{res['details']}'"
        end

        res['results']
      end

      # asks the keychain for all of the account records
      #
      # The hash keys are defined by the +SSKeychain+ library.
      #
      # @see https://github.com/soffes/sskeychain SSKeychain
      #
      # The following keys are the most commonly useful:
      #
      #     +svce+ #=> the service
      #     +acct+ #=> the account (often a username)
      #     +cdat+ #=> the creation date
      #     +mdat+ #=> the last-modified date
      #
      # @raise [RuntimeError] if http request does not report success
      # @return [Array<Hash>] of all account records saved in the iOS keychain.
      def keychain_accounts
        _keychain_get
      end

      # @return [Array<Hash>] of all account records saved in the iOS keychain
      # filtered by +service+.
      #
      # @see keychain_accounts
      #
      # @raise [RuntimeError] if http request does not report success
      def keychain_accounts_for_service(service)
        _keychain_get({:service => service})
      end

      # ask the keychain for an account password
      #
      #     *IMPORTANT*
      #     On the XTC, the password cannot returned as plain text.
      #     When using this keychain_password in your steps you can condition on
      #     the XTC environment using +xamarin_test_cloud?+
      #
      # @see Calabash::Cucumber::EnvironmentHelpers
      #
      # @raise [RuntimeError] if http request does not report success
      # @raise [RuntimeError] if +service+ and +account+ pair does not contain
      #   a password
      #
      # @return [String,Array<Hash>] password stored in keychain for +service+
      #   and +account+.  *NB* on the XTC this returns an Array with one Hash
      def keychain_password(service, account)
        _keychain_get({:service => service, :account => account}).first
      end

      # sends appropriately-configured +POST+ request to the +keychain+ server
      # endpoint.  do not call this function directly; use one of the helper
      # functions provided.
      #
      # @see keychain_clear
      # @see keychain_clear_accounts_for_service
      # @see keychain_delete_password
      # @see keychain_set_password
      #
      # @return [nil]
      # @raise [RuntimeError] if http request does not report success
      def _keychain_post(options={})
        raw = http({:method => :post, :path => 'keychain'}, options)
        res = JSON.parse(raw)
        if res['outcome'] != 'SUCCESS'
          raise "post keychain with options '#{options}' failed because: #{res['reason']}\n#{res['details']}"
        end
        nil
      end

      # On the iOS Simulator this clears *all* keychain entries for *all*
      # applications.
      #
      # On a physical device, this will clear all entries for the target
      # application.
      #
      # @return [nil]
      #
      # @raise [RuntimeError] if http request does not report success
      def keychain_clear
        _keychain_post
      end

      # Clear all entries in the keychain restricted to a single +service+.
      #
      # @return [nil]
      #
      # @raise [RuntimeError] if http request does not report success
      def keychain_clear_accounts_for_service(service)
        _keychain_post({:service => service})
      end

      # Delete a single keychain record for the given +service+ and +account+
      # pair.
      #
      # @raise [RuntimeError] if http request does not report success
      def keychain_delete_password(service, account)
        _keychain_post(:service => service, :account => account)
      end

      # Set the password for a given service and account pair.
      #
      # @return nil
      #
      # @raise [RuntimeError] if http request does not report success
      def keychain_set_password(service, account, password)
        _keychain_post(:service => service, :account => account, :password => password)
      end

    end
  end
end
