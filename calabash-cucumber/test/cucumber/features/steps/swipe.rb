Then(/^I can swipe to go back to the Pan menu$/) do
  x_offset = -1 * query("*")[0]["rect"]["width"] / 2.0
  swipe(:left, {:query => "*", :duration => 0.7, :force => :strong, :offset => { :x => x_offset, :y => 0}})
  wait_for_animations
  wait_for_view("* marked:'pan page'")
end
