module Briar
  module Issue_156
    def orientation_stats
      d = device_orientation
      sb = status_bar_orientation
      { :device => d,
        :status_bar => sb,
        :eql => d.eql?(sb)}
    end

    def should_have_eql_orientations
      stats = orientation_stats
      unless stats[:eql]
        screenshot_and_raise "expected device orientation '#{stats[:device]}' to be the same as status bar orientation '#{stats[:status_bar]}'"
      end
    end

    def rotate_so_home_is_on (home_position)
      home_position = 'down' if home_position.eql?('bottom')
      home_position = 'up' if home_position.eql?('top')
      rotate_home_button_to home_position
      wait_for_none_animating
    end
  end
end

World(Briar::Issue_156)

Then(/^I rotate the device (\d+) times in a random direction$/) do |n|
  n.to_i.times {
    rotate ([:left, :right].sample)
    wait_for_none_animating
  }
end

Then(/^I rotate the device so the home button is on the (right|left|bottom|top)$/) do |home_position|
  rotate_so_home_is_on home_position
end

Then(/^the orientation of the status bar and device should be same$/) do
  should_have_eql_orientations
end
