WAIT_TIMEOUT = (ENV['WAIT_TIMEOUT'] || 30).to_f
STEP_PAUSE = (ENV['STEP_PAUSE'] || 0.5).to_f

Given /^(my|the) app is running$/ do |_|
  # no-op exists for backwards compatibility
end

### Touch ###
Then /^I (?:press|touch) on screen (\d+) from the left and (\d+) from the top$/ do |x, y|
  touch(nil, { offset: { x: x.to_i, y: y.to_i } })
  sleep(STEP_PAUSE)
end

Then /^I (?:press|touch) "([^\"]*)"$/ do |name|
  touch("view marked: '#{name}'")
  sleep(STEP_PAUSE)
end

Then /^I (?:press|touch) (\d+)% right and (\d+)% down from "([^\"]*)"$/ do |x, y, name|
  raise 'This step is not yet implemented on iOS'
end

Then /^I (?:press|touch) button number (\d+)$/ do |index|
  index = index.to_i
  screenshot_and_raise("Index should be positive (was: #{index})") if index <= 0
  touch("button index: #{index - 1}")
  sleep(STEP_PAUSE)
end

Then /^I (?:press|touch) the "([^\"]*)" button$/ do |name|
  touch("button marked: '#{name}'")
  sleep(STEP_PAUSE)
end

Then /^I (?:press|touch) (?:input|text) field number (\d+)$/ do |index|
  index = index.to_i
  screenshot_and_raise("Index should be positive (was: #{index})") if index <= 0
  touch("textField index: #{index - 1}")
  sleep(STEP_PAUSE)
end

Then /^I (?:press|touch) the "([^\"]*)" (?:input|text) field$/ do |name|
  placeholder_query = "textField placeholder: '#{name}'"
  marked_query = "textField marked: '#{name}'"
  if !query(placeholder_query).empty?
    touch(placeholder_query)
  elsif !query(marked_query).empty?
    touch(marked_query)
  else
    screenshot_and_raise "Could not find text field with placeholder '#{name}' or marked as '#{name}'"
  end
  sleep(STEP_PAUSE)
end

# Note in tables views: this means visible cell index!
Then /^I (?:press|touch) list item number (\d+)$/ do |index|
  index = index.to_i
  screenshot_and_raise("Index should be positive (was: #{index})") if index <= 0
  touch("tableViewCell index: #{index - 1}")
  sleep(STEP_PAUSE)
end

Then /^I (?:press|touch) list item "([^\"]*)"$/ do |cell_name|
  if query("tableViewCell marked: '#{cell_name}'").empty?
    touch("tableViewCell text: '#{cell_name}'")
  else
    touch("tableViewCell marked: '#{cell_name}'")
  end
  sleep(STEP_PAUSE)
end

Then /^I toggle the switch$/ do
  touch('switch')
  sleep(STEP_PAUSE)
end

Then /^I toggle the "([^\"]*)" switch$/ do |name|
  touch("switch marked: '#{name}'")
  sleep(STEP_PAUSE)
end

Then /^I touch (?:the)? user location$/ do
  touch("view: 'MKUserLocationView'")
  sleep(STEP_PAUSE)
end

Then /^I (?:touch|press) (?:done|search)$/ do
  done
  sleep(STEP_PAUSE)
end

### Entering text ###
Then /^I enter "([^\"]*)" into the "([^\"]*)" field$/ do |text_to_type, field_name|
  touch("textField marked: '#{field_name}'")
  wait_for_keyboard
  keyboard_enter_text text_to_type
  sleep(STEP_PAUSE)
end

Then /^I enter "([^\"]*)" into the "([^\"]*)" (?:text|input) field$/ do |text_to_type, field_name|
  touch("textField marked: '#{field_name}'")
  wait_for_keyboard
  keyboard_enter_text text_to_type
  sleep(STEP_PAUSE)
end

# Alias
Then /^I fill in "([^\"]*)" with "([^\"]*)"$/ do |text_field, text_to_type|
  macro %(I enter "#{text_to_type}" into the "#{text_field}" text field)
end

Then /^I use the native keyboard to enter "([^\"]*)" into the "([^\"]*)" (?:text|input) field$/ do |text_to_type, field_name|
  macro %(I touch the "#{field_name}" text field)
  wait_for_keyboard
  keyboard_enter_text(text_to_type)
  sleep(STEP_PAUSE)
end

Then /^I fill in text fields as follows:$/ do |table|
  table.hashes.each do |row|
    macro %(I enter "#{row['text']}" into the "#{row['field']}" text field)
  end
end

Then /^I enter "([^\"]*)" into (?:input|text) field number (\d+)$/ do |text, index|
  index = index.to_i
  screenshot_and_raise("Index should be positive (was: #{index})") if index <= 0
  touch("textField index: #{index - 1}")
  wait_for_keyboard
  keyboard_enter_text text
  sleep(STEP_PAUSE)
end

Then /^I use the native keyboard to enter "([^\"]*)" into (?:input|text) field number (\d+)$/ do |text_to_type, index|
  macro %(I touch text field number #{index})
  wait_for_keyboard
  keyboard_enter_text(text_to_type)
  sleep(STEP_PAUSE)
end

When /^I clear "([^\"]*)"$/ do |name|
  msg = "When I clear <name>' will be deprecated because it is ambiguous - what should be cleared?"
  _deprecated('0.9.151', msg, :warn)
  clear_text("textField marked: '#{name}'")
end

Then /^I clear (?:input|text) field number (\d+)$/ do |index|
  index = index.to_i
  screenshot_and_raise("Index should be positive (was: #{index})") if index <= 0
  clear_text("textField index: #{index - 1}")
end

### See ###
Then /^I wait to see "([^\"]*)"$/ do |expected_mark|
  wait_for(WAIT_TIMEOUT) { view_with_mark_exists(expected_mark) }
end

Then /^I wait until I don't see "([^\"]*)"$/ do |expected_mark|
  sleep 1 # wait for previous screen to disappear
  wait_for(WAIT_TIMEOUT) { !element_exists("view marked: '#{expected_mark}'") }
end

Then /^I wait to not see "([^\"]*)"$/ do |expected_mark|
  macro %(I wait until I don't see "#{expected_mark}")
end

Then /^I wait for "([^\"]*)" to appear$/ do |name|
  macro %(I wait to see "#{name}")
end

Then /^I wait for the "([^\"]*)" button to appear$/ do |name|
  wait_for(WAIT_TIMEOUT) { element_exists("button marked: '#{name}'") }
end

Then /^I wait to see a navigation bar titled "([^\"]*)"$/ do |expected_mark|
  msg = "Waited for '#{WAIT_TIMEOUT}' seconds but did not see the navbar with title '#{expected_mark}'"
  wait_for(timeout: WAIT_TIMEOUT, timeout_message: msg ) do
    all_items = query("navigationItemView marked: '#{expected_mark}'")
    button_items = query('navigationItemButtonView')
    non_button_items = all_items.delete_if { |item| button_items.include?(item) }
    !non_button_items.empty?
  end
end

Then /^I wait for the "([^\"]*)" (?:input|text) field$/ do |placeholder_or_view_mark|
  wait_for(WAIT_TIMEOUT) do
    element_exists("textField placeholder: '#{placeholder_or_view_mark}'") ||
    element_exists("textField marked: '#{placeholder_or_view_mark}'")
  end
end

Then /^I wait for (\d+) (?:input|text) field(?:s)?$/ do |count|
  wait_for(WAIT_TIMEOUT) { query(:textField).count >= count.to_i }
end

Then /^I wait$/ do
  sleep 2
end

Then /^I wait and wait$/ do
  sleep 4
end

Then /^I wait and wait and wait...$/ do
  sleep 10
end

When /^I wait for ([\d\.]+) second(?:s)?$/ do |num_seconds|
  sleep num_seconds.to_f
end

Then /^I go back$/ do
  touch('navigationItemButtonView first')
  sleep(STEP_PAUSE)
end

Then /^(?:I\s)?take (?:picture|screenshot)$/ do
  sleep(STEP_PAUSE)
  screenshot_embed
end

Then /^I swipe (left|right|up|down)$/ do |dir|
  swipe(dir)
  sleep(STEP_PAUSE)
end

Then /^I swipe (left|right|up|down) on number (\d+)$/ do |dir, index|
  index = index.to_i
  screenshot_and_raise("Index should be positive (was: #{index})") if index <= 0
  swipe(dir, { query: "scrollView index: #{index - 1}" })
  sleep(STEP_PAUSE)
end

Then /^I swipe (left|right|up|down) on number (\d+) at x (\d+) and y (\d+)$/ do |dir, index, x, y|
  index = index.to_i
  screenshot_and_raise("Index should be positive (was: #{index})") if index <= 0
  swipe(dir, { offset: { x: x.to_i, y: y.to_i }, query: "scrollView index: #{index - 1}" })
  sleep(STEP_PAUSE)
end

Then /^I swipe (left|right|up|down) on "([^\"]*)"$/ do |dir, mark|
  swipe(dir, { query: "view marked: '#{mark}'" })
  sleep(STEP_PAUSE)
end

Then /^I swipe on cell number (\d+)$/ do |index|
  index = index.to_i
  screenshot_and_raise("Index should be positive (was: #{index})") if index <= 0
  cell_swipe({ query: "tableViewCell index: #{index - 1}" })
  sleep(STEP_PAUSE)
end

### Pinch ###
Then /^I pinch to zoom (in|out)$/ do |in_out|
  pinch(in_out)
  sleep(STEP_PAUSE)
end

Then /^I pinch to zoom (in|out) on "([^\"]*)"$/ do |in_out, name|
  pinch(in_out, { query: "view marked: '#{name}'" })
  sleep(STEP_PAUSE)
end

# Note "up/left/right" seems to be missing on the web base
Then /^I scroll (left|right|up|down)$/ do |dir|
  scroll('scrollView index: 0', dir)
  sleep(STEP_PAUSE)
end

Then /^I scroll (left|right|up|down) on "([^\"]*)"$/ do |dir, name|
  scroll("view marked: '#{name}'", dir)
  sleep(STEP_PAUSE)
end

### Playback ###
Then /^I playback recording "([^\"]*)"$/ do |filename|
  playback(filename)
  sleep(STEP_PAUSE)
end

Then /^I playback recording "([^\"]*)" on "([^\"]*)"$/ do |filename, name|
  playback(filename, { query: "view marked: '#{name}'" })
  sleep(STEP_PAUSE)
end

Then /^I playback recording "([^\"]*)" on "([^\"]*)" with offset (\d+),(\d+)$/ do |filename, name, x, y|
  playback(filename, { query: "view marked:'#{name}'", offset: { x: x.to_i, y: y.to_i } })
  sleep(STEP_PAUSE)
end

Then /^I reverse playback recording "([^\"]*)"$/ do |filename|
  playback(filename, { reverse: true })
  sleep(STEP_PAUSE)
end

Then /^I reverse playback recording "([^\"]*)" on "([^\"]*)"$/ do |filename, name|
  playback(filename, { query: "view marked: '#{name}'", reverse: true })
  sleep(STEP_PAUSE)
end

Then /^I reverse playback recording "([^\"]*)" on "([^\"]*)" with offset (\d+),(\d+)$/ do |filename, name, x, y|
  playback(filename, { query: "view marked: '#{name}'", offset: { x: x.to_i, y: y.to_i }, reverse: true })
  sleep(STEP_PAUSE)
end

### Device orientation ###
Then /^I rotate device (left|right)$/ do |dir|
  rotate(dir.to_sym)
  sleep 5 # Servo wait
end

Then /^I send app to background for (\d+) seconds$/ do |secs|
  secs = secs.to_f
  send_app_to_background(secs)
  sleep(secs + 10)
end

### Assertions ###
Then /^I should see "([^\"]*)"$/ do |expected_mark|
  until element_exists("view marked:'#{expected_mark}'") ||
        element_exists("view text:'#{expected_mark}'")
    screenshot_and_raise "No element found with mark or text: #{expected_mark}"
  end
end

Then /^I should not see "([^\"]*)"$/ do |expected_mark|
  res = query("view marked: '#{expected_mark}'")
  res.concat query("view text: '#{expected_mark}'")
  unless res.empty?
    screenshot_and_raise "Expected no element with text nor accessibilityLabel: #{expected_mark}, found #{res.join(', ')}"
  end
end

Then /^I should see a "([^\"]*)" button$/ do |expected_mark|
  check_element_exists("button marked: '#{expected_mark}'")
end
Then /^I should not see a "([^\"]*)" button$/ do |expected_mark|
  check_element_does_not_exist("button marked: '#{expected_mark}'")
end

Then /^I don't see the text "([^\"]*)"$/ do |text|
  macro %(I should not see "#{text}")
end
Then /^I don't see the "([^\"]*)"$/ do |text|
  macro %(I should not see "#{text}")
end

Then /^I see the text "([^\"]*)"$/ do |text|
  macro %(I should see "#{text}")
end

Then /^I see the "([^\"]*)"$/ do |text|
  macro %(I should see "#{text}")
end

Then /^I (?:should)? see text starting with "([^\"]*)"$/ do |text|
  if query("view {text BEGINSWITH '#{text}'}").empty?
    screenshot_and_raise "No text found starting with: #{text}"
  end
end

Then /^I (?:should)? see text containing "([^\"]*)"$/ do |text|
  if query("view {text LIKE '*#{text}*'}").empty?
    screenshot_and_raise "No text found containing: #{text}"
  end
end

Then /^I (?:should)? see text ending with "([^\"]*)"$/ do |text|
  if query("view {text ENDSWITH '#{text}'}").empty?
    screenshot_and_raise "No text found ending with: #{text}"
  end
end

Then /^I see (\d+) (?:input|text) field(?:s)?$/ do |count|
  cnt = query(:textField).count
  if cnt < count.to_i
    screenshot_and_raise "Expected at least #{count} text/input fields, found #{cnt}"
  end
end

Then /^I should see a "([^\"]*)" (?:input|text) field$/ do |expected_mark|
  unless element_exists("textField placeholder: '#{expected_mark}'") ||
         element_exists("textField marked: '#{expected_mark}'")
    screenshot_and_raise "Expected textfield with placeholder or accessibilityLabel: #{expected_mark}"
  end
end

Then /^I should not see a "([^\"]*)" (?:input|text) field$/ do |expected_mark|
  res = query("textField placeholder: '#{expected_mark}'")
  res.concat query("textField marked: '#{expected_mark}'")
  unless res.empty?
    screenshot_and_raise "Expected no textfield with placeholder nor accessibilityLabel: #{expected_mark}, found #{res}"
  end
end

Then /^I should see a map$/ do
  check_element_exists("view: 'MKMapView'")
end

Then /^I should see (?:the)? user location$/ do
  check_element_exists("view: 'MKUserLocationView'")
end

### Date Picker ###

# time_str can be in any format that Time can parse
Then(/^I change the date picker time to "([^"]*)"$/) do |time_str|
  target_time = Time.parse(time_str)
  current_date = date_time_from_picker
  current_date = DateTime.new(current_date.year,
                              current_date.mon,
                              current_date.day,
                              target_time.hour,
                              target_time.min,
                              0,
                              target_time.gmt_offset)
  picker_set_date_time current_date
  sleep(STEP_PAUSE)
end

# date_str can be in any format that Date can parse
Then(/^I change the date picker date to "([^"]*)"$/) do |date_str|
  target_date = Date.parse(date_str)
  current_time = date_time_from_picker
  date_time = DateTime.new(target_date.year,
                           target_date.mon,
                           target_date.day,
                           current_time.hour,
                           current_time.min,
                           0,
                           Time.now.sec,
                           current_time.offset)
  picker_set_date_time date_time
  sleep(STEP_PAUSE)
end

# date_str can be in any format that Date can parse
Then(/^I change the date picker date to "([^"]*)" at "([^"]*)"$/) do |date_str, time_str|
  macro %(I change the date picker time to "#{time_str}")
  macro %(I change the date picker date to "#{date_str}")
end
