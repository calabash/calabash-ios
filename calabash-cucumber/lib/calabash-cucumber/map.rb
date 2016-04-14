require 'json'

module Calabash
  module Cucumber

    # @!visibility private
    module Map

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
      #   > fetch_results("textField", :text)
      #   => [ "old text" ]
      #
      #   # Does not call 'setText:', because :setText is a defined operation.
      #   > fetch_results("textField", :setText, 'new text')
      #   => [ <UITextField ... > ]
      #
      #   # Calls 'setText:', because 'setText:' is not a defined operation.
      #   > fetch_results("textField", 'setText:', 'newer text')
      #   => [ "<VOID>" ]
      #
      #   # Will return [] because :unknownSelector is not defined on UITextField.
      #   > fetch_results("textField", :unknownSelector)
      #   => []
      #
      #   # Will return [] because 'setAlpha' requires 1 argument and none was provided.
      #   # An error will be logged by the server in the device logs.
      #   > fetch_results("textField", 'setAlpha:')
      #   => []
      #
      #
      # Well behaved LPOperations should return the view as JSON objects.
      #
      # @todo Calabash LPOperations should return 'views touched' in JSON format
      def fetch_results(query, method_name, *method_args)
        raw_map(query, method_name, *method_args)['results']
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
      # @see Calabash::Cucumber::Map#fetch_results for examples.
      def raw_map(query, method_name, *method_args)
        operation_map = {
            :method_name => method_name,
            :arguments => method_args
        }
        res = http({:method => :post, :path => 'map'},
                   {:query => query, :operation => operation_map})
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "fetch_results #{query}, #{method_name} failed because: #{res['reason']}\n#{res['details']}"
        end

        res
      end

      # Asserts the result of a calabash `fetch_results` call and raises an error with
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
      # When evaluating whether a `fetch_results` call is successful it is important to
      # note that sometimes a <tt>[ nil ]</tt> or <tt>[nil, <val>, nil]</tt> is
      # a valid result.
      #
      # Consider a controller with 3 labels:
      #
      #    label @ index 0 has text "foo"
      #    label @ index 1 has text nil (the [label text] => nil)
      #    label @ index 2 has text "bar"
      #
      #    fetch_results('label', :text) => ['foo', nil, 'bar']
      #    fetch_results('label index:1', :text) => [nil]
      #
      # In other cases, <tt>[ nil ]</tt> should be treated as an invalid result
      #
      #    # invalid
      #    > mark = 'mark does not exist'
      #    > fetch_results('tableView', :scrollToRowWithMark, mark, args) => [ nil ]
      #
      # Here a <tt>[ nil ]</tt> should be considered invalid because the
      # the operation could not be performed because there is not row that
      # matches `mark`
      def assert_map_results(map_results, msg)
        compact = map_results.compact
        if compact.empty? or compact.member? '<VOID>' or compact.member? '*****'
          screenshot_and_raise msg
        end
      end
    end
  end
end
