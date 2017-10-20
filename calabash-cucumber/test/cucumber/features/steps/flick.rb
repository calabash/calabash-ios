
module TestApp
  module Flick

    def flick_delta_from_radians(radians, element, distance=:normal)
      case distance
        when :normal
          scale_radius_by = 0.333
        when :small
          scale_radius_by = 0.25
        when :long
          scale_radius_by = 0.5
        else
          raise ArgumentError, %Q[

Expected distance: #{distance} to be one of: [:normal, :small, :long]

]
      end

      element_width = element["rect"]["width"]
      element_height = element["rect"]["height"]

      x_center = element["rect"]["center_x"]
      y_center = element["rect"]["center_y"]

      radius = ([element_width, element_height].min) * scale_radius_by

      target_x = x_center + (radius * Math.cos(radians))
      target_y = y_center + (radius * Math.sin(radians))

      {
        x: (x_center - target_x).to_i.to_f,
        y: (y_center - target_y).to_i.to_f
      }
    end

    def flick_delta_from_degrees(degrees, element)
      radians = degrees * Math::PI / 180.0
      flick_delta_from_radians(radians, element)
    end

    def flick_delta_from_direction(direction, element)
      case direction
        when :left
          degrees = 0
        when :up_and_left
          degrees = 45
        when :up
          degrees = 90
        when :up_and_right
          degrees = 135
        when :right
          degrees = 180
        when :down_and_right
          degrees = 225
        when :down
          degrees = 270
        when :down_and_left
          degrees = 315
        else
          raise ArgumentError, %Q[

Expected direction '#{direction}' to be one of:

:left, :up_and_left, :up, :right, :down_and_right, :down, :down_and_left

]
      end

      flick_delta_from_degrees(degrees, element)
    end

    def flick_to(direction, container_view_query, view_query, times, sleep=1.0)
      return if !query(view_query).empty?

      found = false

      times.times do
        element = wait_for_view(container_view_query)
        delta = flick_delta_from_direction(direction, element)

        flick(container_view_query, delta)
        sleep(sleep)
        wait_for_animations

        found = !query(view_query).empty?

        break if found
      end

      if !found
        fail(%Q[
Flicked :#{direction} #{times} times on:

  #{container_view_query}

but did not see:

  #{view_query}

])
      end
    end
  end
end

World(TestApp::Flick)

Given(/^I see the Apple row$/) do
  element = status_bar_details
  x = element["frame"]["x"] + (element["frame"]["width"]/2.0)
  y = element["frame"]["y"] + (element["frame"]["height"]/2.0)

  touch(nil, {offset: {x: x, y: y}})
  wait_for_animations
  wait_for_view("* marked:'apple row'")
end

Then(/^I can flick to the bottom of the Companies table$/) do
  scroll_view_query = "* marked:'table page'"
  view_query = "* marked:'youtube row'"
  flick_to(:up, scroll_view_query, view_query, 2)
end

Then(/^I can flick to the top of the Companies table$/) do
  scroll_view_query = "* marked:'table page'"
  view_query = "* marked:'amazon row'"
  flick_to(:down, scroll_view_query, view_query, 2)
end

Then(/^I center the cayenne box to the middle$/) do
  query = "UIScrollView marked:'scroll'"
  wait_for_view(query)
  query(query, :centerContentToBounds)
  wait_for_animations
  query = "view marked:'cayenne'"
  wait_for_view(query)
  wait_for_animations
end

Then(/^I flick so I can see the (top|bottom|left|right) of the scroll view$/) do |position|
  container_view_query = "* marked:'scroll'"
  wait_for_view(container_view_query)

  case position
    when "top"
      direction = :down
      box_mark = "purple"
    when "bottom"
      direction = :up
      box_mark = "gray"
    when "left"
      direction = :right
      box_mark = "red"
    when "right"
      direction = :left
      box_mark = "dark red"
    else
      raise "Can never get here"
  end

  view_query = "* marked:'#{box_mark}'"

  flick_to(direction, container_view_query, view_query, 3)
end

Then(/^I flick to the (top|bottom) (right|left) of the scroll view$/) do |y, x|
  container_view_query = "* marked:'scroll'"
  wait_for_view(container_view_query)

  case y.to_sym
    when :top
      case x.to_sym
        when :left
          box_mark = "light blue"
          direction = :down_and_right
        when :right
          box_mark = "blue"
          direction = :down_and_left
        else
          raise "Can never get here"
      end
    when :bottom
      case x.to_sym
        when :left
          box_mark = "light gray"
          direction = :up_and_right
        when :right
          box_mark = "dark gray"
          direction = :up_and_left
        else
          raise "Can never get here"
      end
    else
      raise "Can never get here"
  end

  view_query = "* marked:'#{box_mark}'"

  flick_to(direction, container_view_query, view_query, 4, 1.0)
end

When(/^I full-screen flick to go back, I see the Pan menu$/) do
  wait_for_animations

  query = "* marked:'scroll'"
  element = wait_for_view(query)
  element_width = element["rect"]["width"]
  x_center = element["rect"]["center_x"]

  delta = {
    x: element_width/2.0,
    y: 0
  }

  offset = {
    x: -1.0 * x_center,
    y: 0
  }

  flick(query, delta, {offset: offset})
  wait_for_animations

  if uia_available?
    wait_for_view("* marked:'pan page'")
  else
    begin
      wait_for_view("* marked:'pan page'")
    rescue Calabash::Cucumber::WaitHelpers::WaitError => e
      @device_agent_flick_to_go_back_error = e
    end
  end
end

But(/^flick to go back does not work with DeviceAgent$/) do
  if !uia_available?
    expect(@device_agent_flick_to_go_back_error).to be_truthy
  end
end
