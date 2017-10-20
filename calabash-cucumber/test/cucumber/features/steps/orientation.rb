
module UnitTestApp
  module Orientation

    def upside_down_supported?
      ipad?
    end

    def rotate_home_to_and_expect(position)
      symbol = position.to_sym
      orientation = rotate_home_button_to(symbol)

      if [:top, :up].include?(symbol) && !upside_down_supported?
        message = "Up-side-down orientation is not supported on iPhone"
        colored = RunLoop::Color.blue(message)
        $stdout.puts("    #{colored}")
      else
        expected = expected_position(position)
        expect(orientation).to be == expected
      end
    end

    def expected_position(position)
      symbol = position.to_sym
      case symbol
      when :top, :up
        :up
      when :bottom, :down
        :down
      when :right
        :right
      when :left
        :left
      else
        raise ArgumentError, %Q[
Expected '#{position}' to be [:top, :up, :bottom, :down, :left, :right]
]
      end
    end

    def rotate_direction(direction)
      rotate(direction.to_sym)
    end
  end
end

World(UnitTestApp::Orientation)

Then(/^I rotate the device so the home button is on the (top|bottom|left|right)$/) do |position|
  rotate_home_to_and_expect(position)
end

When(/^I rotate the device to the (left|right)$/) do |direction|
  rotate(direction.to_sym)
end

Then(/^the home button is on the (left|right|top|bottom)$/) do |position|
  expected = expected_position(position)
  actual = status_bar_orientation.to_sym

  if actual != expected
    if expected == :up && !upside_down_supported?
      message = "Up-side-down orientation is not supported on iPhone"
      colored = RunLoop::Color.blue(message)
      $stdout.puts("    #{colored}")
    else
      fail %Q[Expected orientation to be #{expected}, but found #{actual}]
    end
  end
end

