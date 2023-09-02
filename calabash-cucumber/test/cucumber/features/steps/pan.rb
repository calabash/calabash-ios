
module TestApp
  module Pan

    def wait_for_external_animations
      wait_for_animations
      delay = RunLoop::Environment.ci? ? 1.0 : 0.5
      sleep(delay)
    end
  end
end

World(TestApp::Pan)

And(/^I am looking at the Pan Palette page$/) do
  wait_for_view("* marked:'pan page'")
  wait_for_view("* marked:'pan palette row'")
  touch("* marked:'pan palette row'")
  wait_for_view("* marked:'pan palette page'")
  wait_for_animations
end

Given(/^I am looking at the Everything's On the Table page$/) do
  wait_for_view("* marked:'table row'")
  touch("* marked:'table row'")
  wait_for_view("* marked:'table page'")
  wait_for_animations
end

Given(/^I am looking at the Scrollplications page$/) do
  wait_for_view("* marked:'scrollplications row'")
  touch("* marked:'scrollplications row'")
  wait_for_view("* marked:'scroll'")
  wait_for_animations
end

Then(/^I can pan to go back to the Pan menu$/) do
  element = wait_for_view("*")
  y = element["rect"]["center_y"]
  final_x = element["rect"]["center_x"] + (element["rect"]["width"]/2)
  pan_coordinates({:x => 0, :y => y},
                  {:x => final_x, :y => y},
                  {duration: 0.5})
  wait_for_animations
  wait_for_view("* marked:'pan page'")
end

Then(/^I can pull down to see the Today and Notifications page$/) do
  if ipad?
    $stdout.puts "Test is not stable on iPad; skipping"
    $stdout.flush
  elsif ios11?
    $stdout.puts "Skipping test on iOS 11, test needs to be written"
    $stdout.puts "due to changes in the Notification Center"
    $stdout.flush
  else
    element = wait_for_view("*")
    x = element["rect"]["center_x"]
    final_y = element["rect"]["center_y"] + (element["rect"]["height"]/2)
    pan_coordinates({:x => x, :y => 0},
                    {:x => x, :y => final_y},
                    {duration: 0.5})

    # Waiting for animations is not good enough - the animation is outside of
    # the AUT's view hierarchy
    wait_for_external_animations

    # Screenshots will not show the iOS Today and Notifications page.
    if uia_available?
      if uia_call_windows([:button, {marked: 'Today'}], :isVisible) != 1
        fail("Expected to see the iOS Today and Notifications page.")
      end
    else
      # Today and Notifications view is invisible to the LPServer and the
      # DeviceAgent queries.  Try to touch a row that is hidden by the page and
      # expect no transition.
      touch("* marked:'pan palette row'")
      wait_for_animations
      if !query("* marked:'pan palette page'").empty?
        fail("Expected to see the iOS Today and Notifications page.")
      end
    end

    y = element["rect"]["height"] - 20
    touch(nil, {offset: {x: x, y: y}})
    wait_for_external_animations

    wait_for_view("* marked:'table row'")
    touch("* marked:'table row'")
    wait_for_view("* marked:'table page'")
    wait_for_animations
  end
end

Then(/^I can pull up to see the Control Panel page$/) do
  if ipad?
    puts "Test is not stable on iPad; skipping"
  else
    element = wait_for_view("*")
    x = element["rect"]["center_x"]
    start_y = element["rect"]["height"] - 10
    final_y = element["rect"]["center_y"] + (element["rect"]["height"]/4)
    pan_coordinates({:x => x, :y => start_y},
                    {:x => x, :y => final_y},
                    {duration: 0.5})

    # Waiting for animations is not good enough - the animation is outside of
    # the AUT's view hierarchy
    wait_for_external_animations

    # Screenshots will not show the Control Panel page.
    if uia_available?
      if uia_call_windows([:button, {marked: 'Camera'}], :isVisible) != 1
         fail("Expected to see the iOS Control page.")
      end

      # This will dismiss the control panel by touching the navigation bar.
      touch("* marked:'Pan Menu'")
    else
      # Control Panel view is invisible to the LPServer and the DeviceAgent queries.
      # Try to touch a row that is hidden by the page and expect no transition.

      # This will dismiss the control panel.
      touch("* marked:'pan palette row'")

      if !query("* marked:'pan palette page'").empty?
        fail("Expected to see the iOS Control panel page.")
      end
    end
  end

  wait_for_external_animations

  wait_for_view("* marked:'table row'")
  touch("* marked:'table row'")
  wait_for_view("* marked:'table page'")
  wait_for_animations
end


