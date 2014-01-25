require 'json'

module Calabash
  module Cucumber
    module Map #=> Connection

      # returns an array of views matched by the +query+ or the result of
      # performing the Objective-C sequence defined by the +method_name+ and
      # +method_args+ on all the views matched by the +query+
      #
      # the query language is documented here: https://github.com/calabash/calabash-ios/wiki
      #
      # returns a JSON representation of each view that is matched
      #
      # when the +method_name+ is a calabash operation, returns an array that
      # contains the result of calling the objc selector +description+ on each
      # matched view.  these are examples of calabash operations: +:flash+,
      # +:scrollToRowWithMark+, +:changeDatePickerDate+.
      def map(query, method_name, *method_args)
        #todo calabash operations should return 'views touched' in JSON format
        raw_map(query, method_name, *method_args)['results']
      end

      # returns a JSON object the represents the result of performing an http
      # query against the calabash server.
      #
      # gem users should _not_ call this method directly; call +map+ instead.
      #
      # raises an error and takes a screenshot if the value of the +outcome+ key
      # is _not_ 'SUCCESS'
      #
      # the JSON object contains the following keys:
      #
      #     +outcome+ => indicates the success or failure of the query
      #
      #     +status_bar_orientation+ => the orientation of the status bar
      #
      #     +results+ => views matched by the +query+ or the result of
      #                  performing the Objective-C selector sequence defined by
      #                  the +method_name+ with arguments defined in
      #                  +method_args+ on all views matched by the +query+
      #
      # the query language is documented here: https://github.com/calabash/calabash-ios/wiki
      #
      # here are some examples that clarify how the +method_name+ and +method_args+
      # influence the value of the +results+ key
      #
      # simple examples:
      #
      #    raw_map('label')['result'] #=> [ all visible UILabels ]
      #       raw_map('label', :text) #=> [ the 'text' of all visible UILabels ]
      #
      # example of calling a selector with arguments:
      #
      # <tt>raw_map("tableView marked:'cheeses'", {'numberOfRowsInSection' => 0})) =></tt>
      # <tt>[ the number of rows in the first section of the 'cheeses' table ]</tt>
      #
      # example of calling a selector on view to return an object and then calling
      # another selector on the returned object:
      #
      # <tt>raw_map("pickerView marked:'cheeses'", :delegate, [{pickerView:nil},{titleForRow:1},{forComponent:0}]) =></tt>
      # objc call: <tt>[[pickerView delegate] pickerView:nil titleForRow:1 forComponent:0] =></tt>
      # <tt>['French']</tt>
      def raw_map(query, method_name, *method_args)
        operation_map = {
            :method_name => method_name,
            :arguments => method_args
        }
        res = http({:method => :post, :path => 'map'},
                   {:query => query, :operation => operation_map})
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "map #{query}, #{method_name} failed because: #{res['reason']}\n#{res['details']}"
        end

        res
      end

      # asserts the result of a calabash +map+ call and raises an error with
      # +msg+ if no valid results are found.
      #
      # casual gem users should never need to call this method; this is a
      # convenience method for gem maintainers.
      #
      # raises an error if +map_results+:
      #
      #              is an empty list #=> []
      #    contains a '<VOID>' string #=> [ "<VOID>" ]
      #       contains '*****' string #=> [ "*****"  ]
      #         contains a single nil #=> [ nil ]
      #
      # when evaluating whether a +map+ call is successful it is important to
      # note that sometimes a <tt>[ nil ]</tt> or <tt>[nil, <val>, nil]</tt> is
      # a valid result.
      #
      # consider a controller with 3 labels:
      #
      #    label @ index 0 has text "foo"
      #    label @ index 1 has text nil (the [label text] => nil)
      #    label @ index 2 has text "bar"
      #
      #    map('label', :text) => ['foo', nil, 'bar']
      #    map('label index:1', :text) => [nil]
      #
      # in other cases, <tt>[ nil ]</tt> should be treated as an invalid result
      #
      #    # invalid
      #    > mark = 'mark does not exist'
      #    > map('tableView', :scrollToRowWithMark, mark, args) => [ nil ]
      #
      # here a <tt>[ nil ]</tt> should be considered invalid because the
      # the operation could not be performed because there is not row that
      # matches +mark+
      def assert_map_results(map_results, msg)
        compact = map_results.compact
        if compact.empty? or compact.member? '<VOID>' or compact.member? '*****'
          screenshot_and_raise msg
        end
      end

    end
  end
end