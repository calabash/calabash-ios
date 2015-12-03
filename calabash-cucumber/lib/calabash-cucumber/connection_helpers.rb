require 'calabash-cucumber/connection'

module Calabash
  module Cucumber

    class ResponseError < RuntimeError ; end

    # @!visibility private
    module ConnectionHelpers

      # @!visibility private
      def http(*args)
        connection.http(*args)
      end

      # @!visibility private
      def connection
        Calabash::Cucumber::Connection.instance
      end

      # @!visibility private
      def response_body_to_hash(body)
        if body.nil? || body == ""
          raise ResponseError,
            "Server replied with an empty response.  Your app has probably crashed"
        end

        begin
          hash = JSON.parse(body)
        rescue TypeError, JSON::ParserError => e
          raise ResponseError,
%Q{Could not parse server response '#{body}':

#{e}

This usually means your app has crashed.
}
        end

        outcome = hash['outcome']

        case outcome
          when 'FAILURE'
            reason = hash['reason']
            if reason.nil? || reason.empty?
              hash['reason'] = 'Server provided no reason.'
            end

            details = hash['details']
            if details.nil? || details.empty?
              hash['details'] = 'Server provided no details.'
            end

          when 'SUCCESS'
            if !hash.has_key?('results')
              raise ResponseError,
%Q{Server responded with '#{outcome}'
but response #{hash} does not contain 'results' key
}
            end
          else
            raise ResponseError,
%Q{Server responded with an invalid outcome: '#{hash["outcome"]}'}
        end
        hash
      end

    end
  end
end
