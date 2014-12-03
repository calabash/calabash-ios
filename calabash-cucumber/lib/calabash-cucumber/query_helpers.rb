module Calabash
  module Cucumber

    # A module of methods that can help you construct queries.
    module QueryHelpers

      # call this method to properly escape strings with single quotes and
      # black slashes in methods (queries and uia actions)
      # Calabash iOS has some annoying rules for text containing single quotes,
      # and even moreso for backslash (\).
      # This helper frees you from manual escaping.
      # @example
      #   quoted = escape_string("Karl's \\ annoying problem")
      #   # => "Karl\\'s \\\\ annoying problem"
      # @param {String} str string to escape
      # @return {String} escaped version of `str`
      def escape_string(str)
        escape_newlines(escape_quotes(escape_backslashes(str)))
      end

      # call this method to properly escape blackslashes (\) in Calabash methods
      # (queries and uia actions).
      # Calabash iOS has some annoying rules for text containing single quotes,
      # and even moreso for backslash (\).
      # This helper frees you from manual escaping.
      # @note
      #  In ruby it is important to remember that "\\" is a *single character* string containing
      #  a backslash: \
      #
      # @example
      #   quoted = escape_backslashes("Karl's \\ annoying problem")
      #   # => "Karl's \\\\ annoying problem"
      # @param {String} str string to escape
      # @return {String} escaped version of `str`
      def escape_backslashes(str)
        backslash = "\\"
        str.gsub(backslash, backslash*4)
      end

      # call this method to properly escape newlines (\n) in Calabash methods
      # (queries and uia actions).
      # This helper frees you from manual escaping.
      # Note entering a 'newline' character only works in iOS UITextViews
      # @note
      #  In ruby it is important to remember that "\n" is a *single character* string containing
      #  a new-line.
      #
      # @example
      #   quoted = escape_newlines("Karl's \n annoying problem")
      #   # => "Karl's \\n annoying problem"
      # @param {String} str string to escape
      # @return {String} escaped version of `str`
      def escape_newlines(str)
        nl = "\n"
        str.gsub(nl, "\\n")
      end

      # call this method to properly escape single quotes in Calabash queries
      # Calabash iOS has some annoying rules for text containing single quotes.
      # This helper frees you from manual escaping.
      # @example
      #   quoted = escape_quotes("Karl's child")
      #   # => "Karl\\'s child"
      # @param {String} str string to escape
      # @return {String} escaped version of `str`
      def escape_quotes(str)
        str.gsub("'", "\\\\'")
      end

      # converts a query result or off-set hash to a point hash
      # @!visibility private
      def point_from(query_result, options={})
        offset_x = 0
        offset_y = 0
        if options[:offset]
          offset_x += options[:offset][:x] || 0
          offset_y += options[:offset][:y] || 0
        end
        x = offset_x
        y = offset_y
        rect = query_result['rect'] || query_result[:rect]
        if rect
          x += rect['center_x'] || rect[:center_x] || rect[:x] || 0
          y += rect['center_y'] || rect[:center_y] || rect[:y] || 0
        else
          x += query_result['center_x'] || query_result[:center_x] || query_result[:x] || 0
          y += query_result['center_y'] || query_result[:center_y] || query_result[:y] || 0
        end

        {:x => x, :y => y}
      end

    end
  end
end