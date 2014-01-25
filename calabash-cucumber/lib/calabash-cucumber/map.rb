require 'json'

module Calabash
  module Cucumber
    module Map #=> Connection

      def map(query, method_name, *method_args)
        raw_map(query,method_name, *method_args)['results']
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

    end
  end
end