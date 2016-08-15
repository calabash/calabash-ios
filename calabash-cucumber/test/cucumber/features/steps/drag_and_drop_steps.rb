module CalSmokeApp
  module DragAndDrop

    class Color
      attr_reader :red, :green, :blue

      def initialize(red, green, blue)
        @red = red
        @green = green
        @blue = blue
      end

      def to_s
        "#<Color #{red}, #{green}, #{blue}>"
      end

      def inspect
        to_s
      end

      def self.color_with_hash(hash)
        red = (hash['red'] * 256).to_i
        green = (hash['green'] * 256).to_i
        blue = (hash['blue'] * 256).to_i

        Color.new(red, green, blue)
      end

      def == (other)
        [red == other.red,
         green == other.green,
         blue == other.blue].all?
      end

      def self.red
        Color.new(153, 39, 39)
      end

      def self.blue
        Color.new(29, 90, 171)
      end

      def self.green
        Color.new(33, 128, 65)
      end
    end

    def frame_equal(a, b)
      [a['x'] == b['x'],
       a['y'] == b['y'],
       a['height'] == b['height'],
       a['width'] == b['width']].all?
    end

    def color_for_box(box_id)
      case box_id
        when 'red'
          Color.red
        when 'green'
          Color.green
        when 'blue'
          Color.blue
        else
          raise "Unknown box_id '#{box_id}'. Expected red, blue, or green"
      end
    end
  end
end

World(CalSmokeApp::DragAndDrop)

When(/^I drag the (red|blue|green) box to the (left|right) well$/) do |box, well|
  from_query = "UIImageView marked:'#{box}'"
  to_query = "UIView marked:'#{well} well'"

  wait_for_elements_exist([from_query, to_query])

  @dragged_box_query = from_query
  @dragged_box_start_frame = query(from_query).first['frame']
  @target_well_query = to_query
  @final_color_of_target_well = color_for_box(box)

  wait_for_none_animating
  pan(from_query, to_query, {duration: 1.0})
end

Then(/^the well should change color$/) do
  query = @target_well_query
  result = query(query, :backgroundColor)
  actual = CalSmokeApp::DragAndDrop::Color.color_with_hash(result.first)
  expect(actual).to be == @final_color_of_target_well
end

And(/^the box goes back to its original position$/) do
  query = @dragged_box_query
  box_id = query.split('marked:')[1]
  timeout = 4
  message = "Waited #{timeout} seconds for '#{box_id}' box to return to original position."
  options = {timeout: timeout, timeout_message: message}
  wait_for(options) do
    result = query(query)
    if result.empty?
      false
    else
      actual = result.first['frame']
      frame_equal(actual, @dragged_box_start_frame)
    end
  end
end
