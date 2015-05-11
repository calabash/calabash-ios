require 'calabash-cucumber/core'

module Calabash
  module Cucumber
    # KeychainHelpers provide a helpers to access the iOS keychain.
    #
    # ### Simulator Note
    #
    # When running on the simulator, the keychain is *not* sandboxed between
    # applications like it is on a real device. These methods will return
    # keychain records from *all* applications on the simulator, which may
    # result in strange behavior if you aren't expecting it.
    #
    # @see http://goo.gl/JrFJMM Details about why some operations report
    #   `FAILURE` and what can be done on the client side mitigate.
    #
    # @see https://github.com/soffes/sskeychain SSKeychain
    module KeychainHelpers


      # @!visibility private
      # Sends appropriately-configured `GET` request to the `keychain` server
      # endpoint.  Do not call this function directly; use one of the helper
      # functions provided.
      #
      # @see #keychain_accounts
      # @see #keychain_account_for_service
      # @return [Array<Hash>] contents of the iOS keychain
      # @param [Hash] options
      # @raise [RuntimeError] if http request does not report success
      def _keychain_get(options={})
        raw = http({:method => :get, :raw => true, :path => 'keychain'}, options)

        begin
          res = JSON.parse(raw)
        rescue TypeError, JSON::ParserError => _
          raise "Could not parse response '#{res}'; the app might have crashed or the server responded with invalid JSON."
        end

        if res['outcome'] != 'SUCCESS'
          raise "get keychain with options '#{options}' failed because: '#{res['reason']}'\n'#{res['details']}'"
        end

        res['results']
      end

      # Asks the keychain for all of the account records.
      #
      # The hash keys are defined by the `SSKeychain` library.
      #
      # @see https://github.com/soffes/sskeychain SSKeychain
      #
      # The following keys are the most commonly useful:
      #
      # ```
      # svce #=> the service
      # acct #=> the account (often a username)
      # cdat #=> the creation date
      # mdat #=> the last-modified date
      # ```
      #
      # @raise [RuntimeError] if http request does not report success
      # @return [Array<Hash>] of all account records saved in the iOS keychain.
      def keychain_accounts
        _keychain_get
      end

      # Returns an list of all account records saved in the iOS keychain
      # filtered by `service`.
      #
      # @see #keychain_accounts
      #
      # @param [String] service the service whose accounts you are requesting
      # @return [Array<Hash>] a list all account records filtered by `service`.
      # @raise [RuntimeError] if http request does not report success
      def keychain_accounts_for_service(service)
        _keychain_get({:service => service})
      end

      # Ask the keychain for an account password.
      #
      # @note
      #  **IMPORTANT**
      #  On the XTC, the password cannot returned as plain text.
      #  When using this keychain_password in your steps you can condition on
      #  the XTC environment using `xamarin_test_cloud?`
      #
      # @see Calabash::Cucumber::EnvironmentHelpers#xamarin_test_cloud?
      #
      # @raise [RuntimeError] if http request does not report success
      # @raise [RuntimeError] if `service` and `account` pair does not contain
      #   a password
      #
      # @return [String,Array<Hash>] password stored in keychain for `service`
      #   and `account`.  *NB* on the XTC this returns an Array with one Hash.
      def keychain_password(service, account)
        _keychain_get({:service => service, :account => account}).first
      end

      # @!visibility private
      # Sends appropriately-configured `POST` request to the `keychain` server
      # endpoint.  Do not call this function directly; use one of the helper
      # functions provided.
      #
      # @see #keychain_clear
      # @see #keychain_clear_accounts_for_service
      # @see #keychain_delete_password
      # @see #keychain_set_password
      #
      # @return [nil]
      # @raise [RuntimeError] if http request does not report success
      def _keychain_post(options={})
        raw = http({:method => :post, :path => 'keychain'}, options)
        begin
          res = JSON.parse(raw)
        rescue TypeError, JSON::ParserError => _
          raise "Could not parse response '#{res}'; the app might have crashed or the server responded with invalid JSON."
        end
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

      # Clear all entries in the keychain restricted to a single `service`.
      #
      # @param [String] service filters which accounts should be cleared.
      # @return [nil]
      #
      # @raise [RuntimeError] if http request does not report success
      def keychain_clear_accounts_for_service(service)
        _keychain_post({:service => service})
      end

      # Delete a single keychain record for the given `service` and `account`
      # pair.
      #
      # @param [String] service filters which accounts should be cleared.
      # @param [String] account filters which account to clear
      #
      # @raise [RuntimeError] if http request does not report success
      def keychain_delete_password(service, account)
        _keychain_post(:service => service, :account => account)
      end

      # Set the password for a given service and account pair.
      #
      # @param [String] service which service to update
      # @param [String] account which account to update
      # @param [String] password which password to set
      # @return nil
      #
      # @raise [RuntimeError] if http request does not report success
      def keychain_set_password(service, account, password)
        _keychain_post(:service => service, :account => account, :password => password)
      end

    end
  end
end
