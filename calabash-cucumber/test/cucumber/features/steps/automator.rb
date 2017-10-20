module TestApp
  module Automator

    def normalize_element(element)
      normal = element.dup
      if uia_available?
        normal["id"] = element["name"]
        hp = element["hit-point"]
        if hp.empty?
          normal["hitable"] = false
          normal["hit_point"] = {"x": -1, "y": -1}
        else
          normal["hitable"] = true
          normal["hit_point"] = hp
        end
      else
        normal.delete("test_id")
      end
      normal
    end

    def normalize_elements(elements)
      elements.map { |element| normalize_element(element) }
    end

    def with_correct_automator(uia, device_agent)
      if uia_available?
        normalize_elements(uia.call)
      else
        normalize_elements(device_agent.call)
      end
    end
  end
end

World(TestApp::Automator)

Then(/^I query for the Silly Alpha button by mark using id$/) do
  uia = -> { uia_query(:view, {marked: "alpha button"}) }
  da = -> { device_agent.query({marked: "alpha button"}) }

  elements = with_correct_automator(uia, da)

  expect(elements.count).to be == 1
  expect(elements[0]["id"]).to be == "alpha button"
end

Then(/^I query for the Silly Zero button by mark using the title$/) do
  uia = -> { uia_query(:view, {marked: "alpha button"}) }
  da = -> { device_agent.query({marked: "alpha button"}) }

  elements = with_correct_automator(uia, da)

  expect(elements.count).to be == 1
  expect(elements[0]["id"]).to be == "alpha button"
end

Then(/^UIA and DeviceAgent can find views that are hidden$/) do
  # Note: :all is not required for uia_query
  uia = -> { uia_query(:view, {marked: "hidden button"}) }
  da = -> { device_agent.query({marked: "hidden button", all: true}) }

  elements = with_correct_automator(uia, da)

  expect(elements.count).to be == 1
  expect(elements[0]["id"]).to be == "hidden button"
end

Then(/^UIA and DeviceAgent results can be filtered by visibility$/) do
  # Note: uia_query returns the element with "hit-point" => {}
  uia = -> { uia_query(:view, {marked: "hidden button"}) }
  da = -> { device_agent.query({marked: "hidden button", all: false}) }

  elements = with_correct_automator(uia, da)

  if uia_available?
    expect(elements.count).to be == 1
    expect(elements[0]["hit-point"]).to be == {}
  else
    expect(elements.count).to be == 0
  end
end

Then(/^I can query by text$/) do
  uia = -> { uia_query(:view, {label: "Silly Buttons"}) }
  # Note: :marked could also be used with device_agent.query
  da = -> { device_agent.query({text: "Silly Buttons"}) }

  elements = with_correct_automator(uia, da)

  expect(elements.count).to be == 1
  expect(elements[0]["label"]).to be == "Silly Buttons"
end

Then(/^I query for Same as views by mark using id$/) do
  query = "* marked:'query row'"
  wait_for_view(query)
  touch(query)
  wait_for_none_animating

  uia = -> { uia_query(:view, {marked: "same as"}) }
  da = -> { device_agent.query({marked: "same as"}) }

  elements = with_correct_automator(uia, da)

  expect(elements.count).to be == 7
end

Then(/^I query for Same as views by mark using id and filter by TextField$/) do
  uia = -> { uia_query(:textField, {marked: "same as"}) }
  da = -> { device_agent.query({type: "TextField", marked: "same as"}) }

  elements = with_correct_automator(uia, da)

  expect(elements.count).to be == 2
end

Then(/^I query for Same as views by mark using id and filter by TextView$/) do
  uia = -> { uia_query(:textView, {marked: "same as"}) }
  da = -> { device_agent.query({type: "TextView", marked: "same as"}) }

  elements = with_correct_automator(uia, da)

  expect(elements.count).to be == 2
end

Then(/^I query for Same as views by mark using id and use an index to find the Button$/) do
  uia = -> { uia_query(:button, {marked: "same as"}) }
  da = -> { device_agent.query({type: "Button", marked: "same as"}) }
  elements = with_correct_automator(uia, da)
  expect(elements.count).to be == 1
  button_result = elements[0]

  uia = -> { uia_query(:view, {marked: "same as"}) }
  da = -> { device_agent.query({marked: "same as", index: 5}) }
  elements = with_correct_automator(uia, da)

  if uia_available?
    expect(elements.count).to be == 7
    index_result = elements[5]
  else
    expect(elements.count).to be == 1
    index_result = elements[0]
  end

  expect(button_result).to be == index_result
end
