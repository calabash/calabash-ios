
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
