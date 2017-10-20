module TestApp
  module Keyboard

    QUESTION = "Ça va?"

    RETURN_KEY_TYPE = {
     "Return" => 0,
     "Go" => 1,
     "Google" => 2,
     "Join" => 3,
     "Next" => 4,
     "Route" => 5,
     "Search" => 6,
     "Send" => 7,
     "Yahoo" => 8,
     "Done" => 9,
     "Emergency call" => 10,
     "Continue" => 11
    }.freeze

    def wait_for_question_text(text)
      wait_for_text_in_view(text, "question")
    end

    def wait_for_question_reset
      wait_for_question_text(QUESTION)
    end

    def wait_for_text_field(text)
      wait_for_text_in_view(text, "text field")
    end

    def text_from_text_field
      query = "* marked:'text field'"
      wait_for_view(query)["text"]
    end

    def wait_for_text_field_reset
      wait_for_question_text(QUESTION)
    end

    def compose_answer(answer)
      "#{QUESTION} - #{answer}"
    end

    def enter_text_with_keyboard(text, timeout=15)
      wait_for_keyboard({:timeout => timeout})
      keyboard_enter_text(text)
      @last_text_entered = text
    end

    def enter_text_with_keyboard_by_character(text, timeout=15)
      query = "* marked:'#{'text field'}'"
      wait_for_view(query)
      touch(query)
      wait_for_keyboard({:timeout => timeout})
      text.each_char do |char|
        keyboard_enter_char(char, {:wait_after_char => 0})
      end
      @last_text_entered = text
    end

    def set_text_with_enter_text(text)
      query = "* marked:'text field'"
      enter_text(query, text)
      @last_text_entered = text
    end

    def set_text_with_fast_enter_text(text)
      query = "* marked:'text field'"
      wait_for_view(query)
      touch(query)
      wait_for_keyboard
      fast_enter_text(text)
      @last_text_entered = text
    end

    def enter_text_in_with_keyboard(mark, text)
      query = "* marked:'#{mark}'"
      wait_for_view(query)
      touch(query)
      wait_for_keyboard
      keyboard_enter_text(text)
      @last_text_entered = text
    end

    def trim_n_chars_from_end(string, n)
      string[0...(-1 * n)]
    end

    def delete_with_backspace_char
      keyboard_enter_char("Delete")
    end

    def delete_last_n_chars(n, delete_with)
      n.times do
        case delete_with
        when :backspace
          delete_with_backspace_char
        when :delete_key
          tap_keyboard_delete_key
        else
          raise ArgumentError, "Unsupported delete_with: #{delete_with}"
        end
      end
    end

    def expect_text(expected, actual, message)
      if expected != actual
        fail(%Q[#{message}:
Expected text: #{expected}
          got: #{actual}
])
      end
    end

    def replace_last_chars(to_replace, replacement, delete_with)
      text_before = text_from_text_field
      n = to_replace.length
      delete_last_n_chars(n, delete_with)

      expected_after_delete = trim_n_chars_from_end(text_before, n)
      actual_after_delete = text_from_text_field
      expect_text(expected_after_delete, actual_after_delete,
                  "Error deleting text")

      enter_text_with_keyboard(replacement)
      tap_keyboard_action_key

      expected_after_replacement = "#{actual_after_delete}#{replacement}"
      actual_after_replacement = text_from_text_field

      expect_text(expected_after_replacement, actual_after_replacement,
                  "Error entering text")
    end

    def set_keyboard_return_key(type)
      number = TestApp::Keyboard::RETURN_KEY_TYPE[type]
      expect(number).not_to be == nil

      query = "* marked:'text field'"
      query(query, {setReturnKeyType:number})

      expect(query(query, :returnKeyType).first).to be == number
      @last_return_key_type = number
    end

    def expect_correct_keyboard_return_key
      query = "* marked:'text field'"
      wait_for_view(query)
      touch(query)
      wait_for_keyboard
      actual = query(query, :returnKeyType).first

      expect(actual).to be == @last_return_key_type
    end

    def dismiss_keyboard_with_action_key
      tap_keyboard_action_key
      wait_for_no_keyboard
    end

    def dismiss_keyboard_with_newline
      keyboard_enter_char("Return")
    end
  end
end

World(TestApp::Keyboard)

And(/^I am looking at the Text Input page$/) do
  touch("* marked:'Misc'")
  sleep(0.4)
  touch("* marked:'Misc'")
  wait_for_none_animating
  touch("* marked:'text input row'")
  wait_for_view("* marked:'text input page'")
  wait_for_none_animating
end

And(/^the text field and question label are reset$/) do
  query = "* marked:'question'"
  wait_for_view(query)
  touch(query)
  wait_for_question_reset

  query = "* marked:'clear text field button'"
  wait_for_view(query)
  touch(query)
  wait_for_text_field_reset
end

When(/^I try to type without the keyboard$/) do
  expect(keyboard_visible?).to be_falsey

  begin
    enter_text_with_keyboard("Gut, und Sie?", 0.5)
  rescue Calabash::Cucumber::WaitHelpers::WaitError => e
    @keyboard_not_visible_error = e
  end
end

Then(/^a keyboard-not-visible error is raised$/) do
  expect(@keyboard_not_visible_error).to be_truthy
  expect(@keyboard_not_visible_error.message[/Keyboard did not appear/]).to be_truthy
end

When(/^I touch the text field$/) do
  query = "* marked:'text field'"
  wait_for_view(query)
  touch(query)
end

Then(/^the keyboard is visible$/) do
  wait_for_keyboard
end

When(/^I type "([^\"]*)"$/) do |text|
  enter_text_with_keyboard(text, 0.5)
end

When(/^I type "([^\"]*)" character by character$/) do |text|
  enter_text_with_keyboard_by_character(text, 0.5)
end

Then(/^what I typed appears in the red box$/) do
  tap_keyboard_action_key
  wait_for_no_keyboard
  answer = compose_answer(@last_text_entered)
  wait_for_question_text(answer)
end

Given(/^I typed "([^\"]*)"$/) do |text|
  enter_text_in_with_keyboard("text field", text)
end

And(/^I decide I should be more formal$/) do
  # nop
end

Then(/^I use enter_text to enter "([^\"]*)"$/) do |text|
  set_text_with_enter_text(text)
end

Then(/^I use fast_enter_text to enter "([^\"]*)"$/) do |text|
  set_text_with_fast_enter_text(text)
end

Given(/^I replace "([^\"]*)" with "([^\"]*)" by sending backspace$/) do |to_replace, replacement|
  replace_last_chars(to_replace, replacement, :backspace)
  text = text_from_text_field
  answer = compose_answer(text)
  wait_for_question_text(answer)
end

And(/^I decide I want to be more emphatic$/) do
  # nop
end

Then(/^I replace "([^\"]*)" with "([^\"]*)" using the delete key$/) do |to_replace, replacement|
  replace_last_chars(to_replace, replacement, :delete_key)
  text = text_from_text_field
  answer = compose_answer(text)
  wait_for_question_text(answer)
end

Then(/^I can dismiss the keyboard on an iPad$/) do
  if ipad?
    dismiss_ipad_keyboard
  else
    expect do
      dismiss_ipad_keyboard
    end.to raise_error RuntimeError, /There is no Hide Keyboard key on an iPhone/
  end
end

Then(/^the return key type of the text field is "([^\"]*)"$/) do |type|
  set_keyboard_return_key(type)
end

When(/^I touch the text field I see the correct return key$/) do
  expect_correct_keyboard_return_key
end

And(/^I can dismiss the keyboard with the action key$/) do
  dismiss_keyboard_with_action_key
end

And(/^I can dismiss a keyboard with a "([^\"]*)" key$/) do |type|
  set_keyboard_return_key(type)
  expect_correct_keyboard_return_key
  dismiss_keyboard_with_action_key
end

Then(/^I can dismiss the keyboard by sending a newline$/) do
  dismiss_keyboard_with_newline
end

When(/^the keyboard is showing, I can ask for the first responder text$/) do
  enter_text_in_with_keyboard("text field", "some text")

  expect(text_from_first_responder).to be == "some text"
end

When(/^the keyboard is not showing, asking for the first responder text raises an error$/) do
  query = "* marked:'text field'"
  query(query, :resignFirstResponder)
  wait_for_no_keyboard

  expect do
    text_from_first_responder
  end.to raise_error RuntimeError, /There must be a visible keyboard/
end

When(/^UIA is available, I can use it to check for keyboards$/) do
  if uia_available?
    query = "* marked:'text field'"
    wait_for_view(query)
    touch(query)
    uia_wait_for_keyboard
  end
end

When(/^UIA is not available, checking for keyboards with UIA raises an error$/) do
  if !uia_available?
    expect do
      uia_wait_for_keyboard
    end.to raise_error RuntimeError, /UIAutomation is not available in Xcode >= 8.0/
  end
end

When(/^the keyboard is not visible expect_keyboard_visible! raises an error$/) do
  query = "* marked:'text field'"
  query(query, :resignFirstResponder)
  wait_for_no_keyboard

  expect do
    expect_keyboard_visible!
  end.to raise_error RuntimeError, /Keyboard is not visible/
end

When(/^the keyboard is visible expect_keyboard_visible! does not raise an error$/) do
  query = "* marked:'text field'"
  wait_for_view(query)
  touch(query)
  expect_keyboard_visible!
end
