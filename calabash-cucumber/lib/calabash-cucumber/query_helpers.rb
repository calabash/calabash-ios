module Calabash
  module Cucumber
    module QueryHelpers

      def escape_quotes(str)
        str.gsub("'", "\\\\'")
      end

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