Then(/^I can swipe to go back to the Pan menu$/) do
  x_offset = -1 * query("*")[0]["rect"]["width"] / 2.0
  ## Uses swipe-delta for instruments since their gesture is slightly not strong enough to open menu
  # this behavior could probably also be changed in the test app
  swipe(:right, {:query => "*", :duration => 0.7, :force => :strong, :offset => {:x => x_offset, :y => 0}, :"swipe-delta" =>{:horizontal => {:dx => -1 * x_offset + 20, :dy => 0}}})
  wait_for_animations
  wait_for_view("* marked:'pan page'")
end
