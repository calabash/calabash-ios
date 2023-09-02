
module TestApp
  module DeviceAgent

    def screenshot_count
      begin
        Calabash::Cucumber::FailureHelpers.class_variable_get(:@@screenshot_count)
      rescue NameError => _
        0
      end
    end

    def expect_device_agent_to_screenshot(method, uiquery=nil)
      if !uia_available?
        original_wait = RunLoop::DeviceAgent::Client::WAIT_DEFAULTS[:timeout]

        hash = uiquery || {marked: "no matching mark"}
        before = screenshot_count
        raised_error = false

        begin
          RunLoop::DeviceAgent::Client::WAIT_DEFAULTS[:timeout] = 0.1

          # BasicObject does not respond to #send
          case method
            when :query_for_coordinate
              device_agent.query_for_coordinate(hash)
            when :touch
              device_agent.touch(hash)
            when :double_tap
              device_agent.double_tap(hash)
            when :two_finger_tap
              device_agent.two_finger_tap(hash)
            when :long_press
              device_agent.long_press(hash, 1.0)
            when :enter_text
              device_agent.enter_text("Some text")
            when :enter_text_in
              device_agent.enter_text_in(hash, "Some text")
            else
              raise ArgumentError, "Unrecognized method: #{method}"
          end
        rescue RuntimeError => _
          raised_error = true
        ensure
          RunLoop::DeviceAgent::Client::WAIT_DEFAULTS[:timeout] = original_wait
        end

        after = screenshot_count
        expect(raised_error).to be_truthy
        expect(before + 1).to be == after
      end
    end
  end
end

World(TestApp::DeviceAgent)

When(/^device_agent\.query_for_coordinate fails, it generates a screenshot$/) do
  expect_device_agent_to_screenshot(:query_for_coordinate)
end

When(/^device_agent\.touch fails, it generates a screenshot$/) do
  expect_device_agent_to_screenshot(:touch)
end

When(/^device_agent\.double_tap fails, it generates a screenshot$/) do
  expect_device_agent_to_screenshot(:double_tap)
end

When(/^device_agent\.two_finger_tap fails, it generates a screenshot$/) do
  expect_device_agent_to_screenshot(:two_finger_tap)
end

When(/^device_agent\.long_press fails, it generates a screenshot$/) do
  expect_device_agent_to_screenshot(:long_press)
end

When(/^device_agent\.enter_text fails, it generates a screenshot$/) do
  expect_device_agent_to_screenshot(:enter_text)
end

When(/^device_agent\.enter_text_in fails, it generates a screenshot$/) do
  expect_device_agent_to_screenshot(:enter_text_in)
end

Then(/^I can open Notifications tab in Today and Notifications page$/) do
  # Timeout for views in Control/Notification Panels to appear
  timeout = 5

  if ipad?
    puts "Test is not stable on iPad; skipping"
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

    # Screenshots will not show the Control Panel page.
    if ios9?
      if uia_available?
        if uia_call_windows([:button, {marked: 'Notifications'}], :isVisible) != 1
          fail("Expected to see 'Notifications' element.")
        end

        uia_tap :button, marked: 'Notifications'
        wait_for_external_animations

        if uia_call_windows([:element, {marked: 'No Notifications'}], :isVisible) != 1
          fail("Expected to see 'No Notifications' element")
        end
      else
        message = "Timed out waiting for 'Notifications' view after #{timeout} seconds"
        bridge_wait_for(message, {timeout: timeout}) do
          !device_agent.query({marked: 'Notifications'}).empty?
        end

        device_agent.touch({:marked => 'Notifications'})

        message = "Timed out waiting for 'No Notifications' view after #{timeout} seconds"
        bridge_wait_for(message, {timeout: timeout}) do
          !device_agent.query({marked: 'No Notifications'}).empty?
        end
      end
    elsif ios10?
      message = "Timed out waiting for 'No Notifications' view after #{timeout} seconds"
      bridge_wait_for(message, {timeout: timeout}) do
        !device_agent.query({marked: 'No Notifications'}).empty?
      end
    end
  end
end

Then(/^I can see Control Panel page elements$/) do

  # Timeout for views in Control/Notification Panels to appear
  timeout = 5
  message = "Timed out waiting for 'Wi-Fi' view after #{timeout} seconds"

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
    if ios9?
      if uia_available?
        if uia_call_windows([:element, {marked: 'Wi-Fi'}], :isVisible) != 1
          fail("Expected to see 'Wi-Fi' element.")
        end
      else
        bridge_wait_for(message, {timeout: timeout}) do
          !device_agent.query({marked: 'Wi-Fi'}).empty?
        end
      end
    elsif ios10?
      # We have to tap on Continue button from Welcome view after sim reset.
      if !device_agent.query({marked: 'Continue'}).empty?
        device.agent.touch({marked: 'Continue'})
        wait_for_external_animations
      end

      bridge_wait_for(message, {timeout: timeout}) do
        !device_agent.query({marked: 'Wi-Fi'}).empty?
      end
    end
  end
end