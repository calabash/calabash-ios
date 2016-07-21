module IPhoneOnly

  def wait_for_view(mark)
    timeout = 8
    message = "Timed out after #{timeout} seconds waiting for '#{mark}'"
    options = {
      :timeout => timeout,
      :timeout_message => message
    }

    qstr = "view marked:'#{mark}'"
    wait_for(options) do
      !query(qstr).empty?
    end

    qstr
  end

  def clear_action_label
    qstr = wait_for_view("action")
    query(qstr, {:setText => ''})
  end

  def touch_box(identifier)
    qstr = wait_for_view(identifier)
    touch(qstr)
  end

  def touch_small_button(y_id, x_id)
    mark = "#{y_id} #{x_id}"
    qstr = wait_for_view(mark)
    touch(qstr)
  end

  def wait_for_text_in_action_label(text)
    qstr = wait_for_view("action")
    actual = query(qstr, :text).first
    expect(actual).to be == text
  end
end

World(IPhoneOnly)

Given(/^the app has launched$/) do
  wait_for do
    !query("*").empty?
  end
end

When(/^I touch the "([^\"]*)" box, the text appears$/) do |text|
  clear_action_label
  touch_box(text)
  wait_for_text_in_action_label(text)
end

When(/^I touch the (top|middle|bottom) (left|middle|right) button, the action text is correct$/) do |y_id, x_id|
  clear_action_label
  touch_small_button(y_id, x_id)
  wait_for_text_in_action_label("#{y_id} #{x_id}")
end

