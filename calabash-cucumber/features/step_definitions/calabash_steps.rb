WAIT_TIMEOUT = (ENV['WAIT_TIMEOUT'] || 30).to_f
STEP_PAUSE = (ENV['STEP_PAUSE'] || 0.5).to_f

Given /^(my|the) app is running$/ do |_|
  #no-op exists for backwards compatibility
end


# -- Touch --#
Then /^I (?:press|touch) on screen (\d+) from the left and (\d+) from the top$/ do |x, y|
  touch(nil, {:offset => {:x => x.to_i, :y => y.to_i}})
  sleep(STEP_PAUSE)
end

Then /^I (?:press|touch) "([^\"]*)"$/ do |name|
  touch("view marked:'#{name}'")
  sleep(STEP_PAUSE)
end

Then /^I (?:press|touch) (\d+)% right and (\d+)% down from "([^\"]*)" $/ do |x,y,name|
  raise "This step is not yet implemented on iOS"
end

Then /^I (?:press|touch) button number (\d+)$/ do |index|
  index = index.to_i
  screenshot_and_raise "Index should be positive (was: #{index})" if (index<=0)
  touch("button index:#{index-1}")
  sleep(STEP_PAUSE)
end

Then /^I (?:press|touch) the "([^\"]*)" button$/ do |name|
  touch("button marked:'#{name}'")
  sleep(STEP_PAUSE)
end

Then /^I (?:press|touch) (?:input|text) field number (\d+)$/ do |index|
  index = index.to_i
  screenshot_and_raise "Index should be positive (was: #{index})" if (index<=0)
  touch("textField index:#{index-1}")
  sleep(STEP_PAUSE)  
end


Then /^I (?:press|touch) the "([^\"]*)" (?:input|text) field$/ do |name|
  placeholder_query = "textField placeholder:'#{name}'"
  marked_query = "textField marked:'#{name}'"
  if !query(placeholder_query).empty?
    touch(placeholder_query)
  elsif !query(marked_query).empty?
    touch(marked_query)
  else
    screenshot_and_raise "could not find text field with placeholder '#{name}' or marked as '#{name}'"
  end
  sleep(STEP_PAUSE)
end

#Note in tables views: this means visible cell index!
Then /^I (?:press|touch) list item number (\d+)$/ do |index|
   index = index.to_i
   screenshot_and_raise "Index should be positive (was: #{index})" if (index<=0)
   touch("tableViewCell index:#{index-1}")
   sleep(STEP_PAUSE)
end

Then /^I (?:press|touch) list item "([^\"]*)"$/ do |cell_name|
  if
  query("tableViewCell marked:'#{cell_name}'").empty?
  then
    touch("tableViewCell text:'#{cell_name}'")
  else
    touch("tableViewCell marked:'#{cell_name}'")
  end
  sleep(STEP_PAUSE)
end

Then /^I toggle the switch$/ do
  touch("switch")
  sleep(STEP_PAUSE)
end

Then /^I toggle the "([^\"]*)" switch$/ do |name|
  touch("switch marked:'#{name}'")
  sleep(STEP_PAUSE)
end

Then /^I touch (?:the)? user location$/ do
  touch("view:'MKUserLocationView'")
  sleep(STEP_PAUSE)
end

Then /^I (?:touch|press) (?:done|search)$/ do
  done
  sleep(STEP_PAUSE)
end


## -- Entering text -- ##

Then /^I enter "([^\"]*)" into the "([^\"]*)" field$/ do |text_to_type, field_name|
  touch("textField marked:'#{field_name}'")
  await_keyboard
  keyboard_enter_text text_to_type
  sleep(STEP_PAUSE)
end

Then /^I enter "([^\"]*)" into the "([^\"]*)" (?:text|input) field$/ do |text_to_type, field_name|
  touch("textField marked:'#{field_name}'")
  await_keyboard
  keyboard_enter_text text_to_type
  sleep(STEP_PAUSE)
end

# alias
Then /^I fill in "([^\"]*)" with "([^\"]*)"$/ do |text_field, text_to_type|
  macro %Q|I enter "#{text_to_type}" into the "#{text_field}" text field|
end

Then /^I use the native keyboard to enter "([^\"]*)" into the "([^\"]*)" (?:text|input) field$/ do |text_to_type, field_name|
  macro %Q|I touch the "#{field_name}" text field|
  await_keyboard()
  keyboard_enter_text(text_to_type)
  sleep(STEP_PAUSE)
end

Then /^I fill in text fields as follows:$/ do |table|
  table.hashes.each do |row|
    macro %Q|I enter "#{row['text']}" into the "#{row['field']}" text field|
  end
end

Then /^I enter "([^\"]*)" into (?:input|text) field number (\d+)$/ do |text, index|
  index = index.to_i
  screenshot_and_raise "Index should be positive (was: #{index})" if (index<=0)
  touch("textField index:#{index-1}")
  await_keyboard()
  keyboard_enter_text text
  sleep(STEP_PAUSE)
end

Then /^I use the native keyboard to enter "([^\"]*)" into (?:input|text) field number (\d+)$/ do |text_to_type, index|
  idx = index.to_i
  macro %Q|I touch text field number #{idx}|
  await_keyboard()
  keyboard_enter_text(text_to_type)
  sleep(STEP_PAUSE)
end

When /^I clear "([^\"]*)"$/ do |name|
  # definition changed - now uses keyboard_enter_text instead of (deprecated) set_text
  # macro %Q|I enter "" into the "#{name}" text field|
  unless ENV['CALABASH_NO_DEPRECATION'] == '1'
    warn "WARNING: 'When I clear <name>' will be deprecated because it is ambiguous - what should be cleared?"
  end
  clear_text("textField marked:'#{name}'")
end

Then /^I clear (?:input|text) field number (\d+)$/ do |index|
  index = index.to_i
  screenshot_and_raise "Index should be positive (was: #{index})" if (index<=0)
  clear_text("textField index:#{index-1}")
end

# -- See -- #
Then /^I wait to see "([^\"]*)"$/ do |expected_mark|
  wait_for(WAIT_TIMEOUT) { view_with_mark_exists( expected_mark ) }
end

Then /^I wait until I don't see "([^\"]*)"$/ do |expected_mark|
  sleep 1## wait for previous screen to disappear
  wait_for(WAIT_TIMEOUT) { not element_exists( "view marked:'#{expected_mark}'" )}
end

Then /^I wait to not see "([^\"]*)"$/ do |expected_mark|
  macro %Q|I wait until I don't see "#{expected_mark}"|
end

Then /^I wait for "([^\"]*)" to appear$/ do |name|
  macro %Q|I wait to see "#{name}"|
end

Then /^I wait for the "([^\"]*)" button to appear$/ do |name|
  wait_for(WAIT_TIMEOUT) { element_exists( "button marked:'#{name}'" ) }
end


Then /^I wait to see a navigation bar titled "([^\"]*)"$/ do |expected_mark|
  wait_for(WAIT_TIMEOUT) do
     query('navigationItemView', :accessibilityLabel).include?(expected_mark)
  end
end

Then /^I wait for the "([^\"]*)" (?:input|text) field$/ do |placeholder_or_view_mark|
  wait_for(WAIT_TIMEOUT) {
    element_exists( "textField placeholder:'#{placeholder_or_view_mark}'") ||
          element_exists( "textField marked:'#{placeholder_or_view_mark}'")
  }
end

Then /^I wait for (\d+) (?:input|text) field(?:s)?$/ do |count|
  count = count.to_i
  wait_for(WAIT_TIMEOUT) { query(:textField).count >= count  }
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
  num_seconds = num_seconds.to_f
  sleep num_seconds
end


Then /^I go back$/ do
  touch("navigationItemButtonView first")
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
  screenshot_and_raise "Index should be positive (was: #{index})" if (index<=0)
  swipe(dir, {:query => "scrollView index:#{index-1}"})
  sleep(STEP_PAUSE)
end

Then /^I swipe (left|right|up|down) on number (\d+) at x (\d+) and y (\d+)$/ do |dir, index, x, y|
  index = index.to_i
  screenshot_and_raise "Index should be positive (was: #{index})" if (index<=0)
  swipe(dir, {:offset => {:x => x.to_i, :y => y.to_i}, :query => "scrollView index:#{index-1}"})
  sleep(STEP_PAUSE)
end

Then /^I swipe (left|right|up|down) on "([^\"]*)"$/ do |dir, mark|
    swipe(dir, {:query => "view marked:'#{mark}'"})
    sleep(STEP_PAUSE)
end

Then /^I swipe on cell number (\d+)$/ do |index|
  index = index.to_i
  screenshot_and_raise "Index should be positive (was: #{index})" if (index<=0)
  cell_swipe({:query => "tableViewCell index:#{index-1}"})
  sleep(STEP_PAUSE)
end


##pinch##
Then /^I pinch to zoom (in|out)$/ do |in_out|
  pinch(in_out)
  sleep(STEP_PAUSE)
end

Then /^I pinch to zoom (in|out) on "([^\"]*)"$/ do |in_out, name|
  pinch(in_out,{:query => "view marked:'#{name}'"})
  sleep(STEP_PAUSE)
end

#   Note "up/left/right" seems to be missing on the web base
Then /^I scroll (left|right|up|down)$/ do |dir|
  scroll("scrollView index:0", dir)
  sleep(STEP_PAUSE)
end

Then /^I scroll (left|right|up|down) on "([^\"]*)"$/ do |dir,name|
  scroll("view marked:'#{name}'", dir)
  sleep(STEP_PAUSE)
end



### Playback ###
Then /^I playback recording "([^\"]*)"$/ do |filename|
    playback(filename)
    sleep(STEP_PAUSE)
end

Then /^I playback recording "([^\"]*)" on "([^\"]*)"$/ do |filename, name|
    playback(filename, {:query => "view marked:'#{name}'"})
    sleep(STEP_PAUSE)
end

Then /^I playback recording "([^\"]*)" on "([^\"]*)" with offset (\d+),(\d+)$/ do |filename, name, x, y|
  x = x.to_i
  y = y.to_i
  playback(filename, {:query => "view marked:'#{name}'", :offset => {:x => x, :y => y}})
  sleep(STEP_PAUSE)
end

Then /^I reverse playback recording "([^\"]*)"$/ do |filename|
  playback(filename, {:reverse => true})
  sleep(STEP_PAUSE)
end

Then /^I reverse playback recording "([^\"]*)" on "([^\"]*)"$/ do |filename, name|
  playback(filename, {:query => "view marked:'#{name}'",:reverse => true})
  sleep(STEP_PAUSE)
end

Then /^I reverse playback recording "([^\"]*)" on "([^\"]*)" with offset (\d+),(\d+)$/ do |filename, name, x, y|
  x = x.to_i
  y = y.to_i
  playback(filename, {:query => "view marked:'#{name}'", :offset => {:x => x, :y => y},:reverse => true})
  sleep(STEP_PAUSE)
end


### Device orientation ###
Then /^I rotate device (left|right)$/ do |dir|
  dir = dir.to_sym
  rotate(dir)
  sleep(5)#SERVO wait
end

Then /^I send app to background for (\d+) seconds$/ do |secs|
  secs = secs.to_f
  background(secs)
  sleep(secs+10)
end

### Assertions ###
Then /^I should see "([^\"]*)"$/ do |expected_mark|
  res = (element_exists( "view marked:'#{expected_mark}'" ) or
         element_exists( "view text:'#{expected_mark}'"))
  if not res
    screenshot_and_raise "No element found with mark or text: #{expected_mark}"
  end
end

Then /^I should not see "([^\"]*)"$/ do |expected_mark|
  res = query("view marked:'#{expected_mark}'")
  res.concat query("view text:'#{expected_mark}'")
  unless res.empty?
    screenshot_and_raise "Expected no element with text nor accessibilityLabel: #{expected_mark}, found #{res.join(", ")}"
  end
end

Then /^I should see a "([^\"]*)" button$/ do |expected_mark|
  check_element_exists("button marked:'#{expected_mark}'")
end
Then /^I should not see a "([^\"]*)" button$/ do |expected_mark|
  check_element_does_not_exist("button marked:'#{expected_mark}'")
end

Then /^I don't see the text "([^\"]*)"$/ do |text|
  macro %Q|I should not see "#{text}"|
end
Then /^I don't see the "([^\"]*)"$/ do |text|
  macro %Q|I should not see "#{text}"|
end

Then /^I see the text "([^\"]*)"$/ do |text|
  macro %Q|I should see "#{text}"|
end
Then /^I see the "([^\"]*)"$/ do |text|
  macro %Q|I should see "#{text}"|
end

Then /^I (?:should)? see text starting with "([^\"]*)"$/ do |text|
  res = query("view {text BEGINSWITH '#{text}'}").empty?
  if res
    screenshot_and_raise "No text found starting with: #{text}"
  end
end

Then /^I (?:should)? see text containing "([^\"]*)"$/ do |text|
  res = query("view {text LIKE '*#{text}*'}").empty?
  if res
    screenshot_and_raise "No text found containing: #{text}"
  end
end

Then /^I (?:should)? see text ending with "([^\"]*)"$/ do |text|
  res = query("view {text ENDSWITH '#{text}'}").empty?
  if res
    screenshot_and_raise "No text found ending with: #{text}"
  end
end

Then /^I see (\d+) (?:input|text) field(?:s)?$/ do |count|
  count = count.to_i
  cnt = query(:textField).count
  if cnt < count
      screenshot_and_raise "Expected at least #{count} text/input fields, found #{cnt}"
  end
end

Then /^I should see a "([^\"]*)" (?:input|text) field$/ do |expected_mark|
  res = element_exists("textField placeholder:'#{expected_mark}'") ||
          element_exists("textField marked:'#{expected_mark}'")
  unless res
    screenshot_and_raise "Expected textfield with placeholder or accessibilityLabel: #{expected_mark}"
  end
end

Then /^I should not see a "([^\"]*)" (?:input|text) field$/ do |expected_mark|
  res = query("textField placeholder:'#{expected_mark}'")
  res.concat query("textField marked:'#{expected_mark}'")
  unless res.empty?
    screenshot_and_raise "Expected no textfield with placeholder nor accessibilityLabel: #{expected_mark}, found #{res}"
  end
end


Then /^I should see a map$/ do
  check_element_exists("view:'MKMapView'")
end

Then /^I should see (?:the)? user location$/ do
  check_element_exists("view:'MKUserLocationView'")
end
