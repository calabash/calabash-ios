module Calabash
  module Cucumber

    # @!visibility private
    class Map

      require "json"
      require "calabash-cucumber/http_helpers"
      require "calabash-cucumber/failure_helpers"

      include Calabash::Cucumber::HTTPHelpers
      include Calabash::Cucumber::FailureHelpers

      # Returns an array of views matched by the `query` or the result of
      # performing the Objective-C sequence defined by the `method_name` and
      # `method_args` on all the views matched by the `query`.
      #
      # This is not a method that users should be calling directly.
      #
      # The `method_name` is typically mapped to an LPOperation on the server.
      # Some examples of LPOperations are:
      #
      #   * :flash
      #   * :scrollToRowWithMark
      #   * :changeDatePickerDate
      #
      # If `method_name` maps to no LPOperation, then it is treated a selector
      # and is performed on any view that matches `query`.
      #
      # @examples
      #
      #   # Calls 'text' on any visible UITextField, because :text is not a defined operation.
      #   > map("textField", :text)
      #   => [ "old text" ]
      #
      #   # Does not call 'setText:', because :setText is a defined operation.
      #   > map("textField", :setText, 'new text')
      #   => [ <UITextField ... > ]
      #
      #   # Calls 'setText:', because 'setText:' is not a defined operation.
      #   > map("textField", 'setText:', 'newer text')
      #   => [ "<VOID>" ]
      #
      #   # Will return [] because :unknownSelector is not defined on UITextField.
      #   > map("textField", :unknownSelector)
      #   => []
      #
      #   # Will return [] because 'setAlpha' requires 1 argument and none was provided.
      #   # An error will be logged by the server in the device logs.
      #   > map("textField", 'setAlpha:')
      #   => []
      #
      #
      # Well behaved LPOperations should return the view as JSON objects.
      #
      # @todo Calabash LPOperations should return 'views touched' in JSON format
      def self.map(query, method_name, *method_args)
        self.raw_map(query, method_name, *method_args)['results']
      end

      # Returns a JSON object the represents the result of performing an http
      # query against the calabash server.
      #
      # Raises an error and takes a screenshot if the value of the `outcome` key
      # is _not_ 'SUCCESS'
      #
      # The JSON object contains the following keys:
      #
      #     `outcome` => indicates the success or failure of the query
      #
      #     `status_bar_orientation` => the orientation of the status bar
      #
      #     `results` => views matched by the `query` or the result of
      #                  performing the Objective-C selector sequence defined by
      #                  the `method_name` with arguments defined in
      #                  `method_args` on all views matched by the `query`
      #
      # @see map for examples.
      def self.raw_map(query, method_name, *method_args)
        if correct_predicate?(query)
          operation_map = {
              :method_name => method_name,
              :arguments => method_args
          }

          route = {:method => :post, :path => "map"}
          parameters = {:query => query,
                        :operation => operation_map}
          body = self.map_factory.http(route, parameters)

          hash = JSON.parse(body)
          if hash["outcome"] != "SUCCESS"
            message = %Q[
              map #{query}, #{method_name} failed for:
              reason: #{hash["reason"]}
              details: #{hash["details"]}
            ]
            self.map_factory.screenshot_and_raise(message)
          end

          hash
        end
      end

      # Asserts the result of a calabash `map` call and raises an error with
      # `msg` if no valid results are found.
      #
      # Casual gem users should never need to call this method; this is a
      # convenience method for gem maintainers.
      #
      # Raises an error if `map_results`:
      #
      #              is an empty list #=> []
      #    contains a '<VOID>' string #=> [ "<VOID>" ]
      #       contains '*****' string #=> [ "*****"  ]
      #         contains a single nil #=> [ nil ]
      #
      # When evaluating whether a `map` call is successful it is important to
      # note that sometimes a <tt>[ nil ]</tt> or <tt>[nil, <val>, nil]</tt> is
      # a valid result.
      #
      # Consider a controller with 3 labels:
      #
      #    label @ index 0 has text "foo"
      #    label @ index 1 has text nil (the [label text] => nil)
      #    label @ index 2 has text "bar"
      #
      #    map('label', :text) => ['foo', nil, 'bar']
      #    map('label index:1', :text) => [nil]
      #
      # In other cases, <tt>[ nil ]</tt> should be treated as an invalid result
      #
      #    # invalid
      #    > mark = 'mark does not exist'
      #    > map('tableView', :scrollToRowWithMark, mark, args) => [ nil ]
      #
      # Here a <tt>[ nil ]</tt> should be considered invalid because the
      # the operation could not be performed because there is not row that
      # matches `mark`
      def self.assert_map_results(map_results, msg)
        compact = map_results.compact
        if compact.empty? or compact.member? '<VOID>' or compact.member? '*****'
          Map.new.screenshot_and_raise msg
        end
      end

      # Evaluating whether a query contain correct predicate selector
      # returs true if query does not include predicate part or include correct
      # predicate selector
      def self.correct_predicate?(query)
        if !query.match(/{.*}/).nil?
          str = query.match(/{.*}/)[0]
          correct = false
          predicate = %w(BEGINSWITH CONTAINS ENDSWITH LIKE MATCHES)
          predicate.each do |value|
            if str.include?(value)
              correct = true
              return correct
            end
          end
          if !correct
            fail "Incorrect predicate used, valid selectors are: #{predicate}"
          end
        else
          return true
        end
      end
      private

      def self.map_factory
        Map.new
      end
    end
  end
end
