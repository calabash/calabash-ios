require 'calabash-cucumber/failure_helpers'

module Calabash
  module Cucumber
    module TestsHelpers

      include Calabash::Cucumber::FailureHelpers

      # Returns the classes of all views matching `uiquery`
      # @param {String} uiquery the query to execute
      # @param {Array} args optional args to pass to `query`.
      # @return {Array<String>} class names of views matching `uiquery`
      def classes(uiquery,*args)
        query_map(uiquery,:class,*args)
      end

      # Returns true if no element matches query `uiquery`.
      # @param {String} uiquery the query to execute
      # @return {Boolean} `true` if no element matches query `uiquery`. `false` otherwise.
      def element_does_not_exist(uiquery)
        query(uiquery).empty?
      end

      # Returns true if at least one element matches query `uiquery`.
      # @param {String} uiquery the query to execute
      # @return {Boolean} `true` if at least one element matches query `uiquery`. `false` otherwise.
      def element_exists(uiquery)
        not element_does_not_exist(uiquery)
      end

      # Returns true if at least one element matches query `"* marked:'#{expected_mark}'"`
      # @param {String} expected_mark the mark to search for
      # @return {Boolean} `true` if at least one element matches query
      #  `"* marked:'#{expected_mark}'". `false` otherwise.
      def view_with_mark_exists(expected_mark)
        element_exists("view marked:'#{expected_mark}'")
      end

      # raises a Runtime error (and generates a screenshot) unless at least one element matches query `query`.
      # @param {String} query the query to execute
      # @return {nil} Returns nil if there is a match.
      # @raise [RuntimeError] if no element matches `query`.
      def check_element_exists(query)
        if not element_exists(query)
          screenshot_and_raise "No element found for query: #{query}"
        end
      end

      # raises a Runtime error (and generates a screenshot) if at least one element matches query `query`.
      # @param {String} query the query to execute
      # @return {nil} Returns nil if there is no match.
      # @raise [RuntimeError] if an element matches `query`.
      def check_element_does_not_exist(query)
        if element_exists(query)
          screenshot_and_raise "Expected no elements to match query: #{query}"
        end
      end

      # raises a Runtime error (and generates a screenshot) unless at least one element matches mark `expected_mark`.
      # @param {String} expected_mark the mark to check for.
      # @return {nil} Returns nil if there is a match.
      # @raise [RuntimeError] if no element matches `view marked:'#{expected_mark}'`.
      def check_view_with_mark_exists(expected_mark)
        check_element_exists("view marked:'#{expected_mark}'")
      end

      # Calls given block with each row and section (`yield(row, sec)`). Alternates between scrolling to each cell and
      # yielding.
      #
      # @param {Hash} opts specifies details of the scroll
      # @option opts {String} :query ('tableView') query specifying which table view to use
      # @option opts {Numeric} :post_scroll (0.3) wait to be done after each scroll
      # @option opts {Boolean} :animated (true) animate or not
      #
      def each_cell(opts={:query => "tableView", :post_scroll => 0.3, :animate => true}, &block)
        uiquery = opts[:query] || "tableView"
        skip = opts[:skip_if]
        check_element_exists(uiquery)
        secs = query(uiquery,:numberOfSections).first
        secs.times do |sec|
          rows = query(uiquery,{:numberOfRowsInSection => sec}).first
          rows.times do |row|
            next if skip and skip.call(row,sec)
            scroll_opts = {:section => sec, :row => row}.merge(opts)
            scroll_to_cell(scroll_opts)
            sleep(opts[:post_scroll]) if opts[:post_scroll] and opts[:post_scroll] > 0
            yield(row, sec)
          end
        end
      end

      # @!visibility private
      def each_cell_and_back(opts={:query => "tableView",
                                   :post_scroll => 0.3,
                                   :post_back => 0.5,
                                   :post_tap_cell => 0.3,
                                   :animate => true}, &block)
        back_query = opts[:back_query] || "navigationItemButtonView"
        post_tap_cell = opts[:post_tap_cell] || 0.3
        post_back = opts[:post_back] || 0.6


        each_cell(opts) do |row, sec|
          touch("tableViewCell indexPath:#{row},#{sec}")
          wait_for_elements_exist([back_query])
          sleep(post_tap_cell) if post_tap_cell > 0

          yield(row,sec) if block_given?

          touch(back_query)

          sleep(post_back) if post_back > 0

        end
      end

      # @!visibility private
      def query_map(uiquery,prop, *args)
        query(uiquery,*args).map {|o| o[prop.to_s]}
      end

    end
  end
end
