Then(/^I can swipe to go back to the Pan menu$/) do
  x_offset = -1 * query("*")[0]["rect"]["width"] / 2.0
  ## Uses swipe-delta for instruments since their gesture is slightly not strong enough to open menu
  # this behavior could probably also be changed in the test app
  swipe(:right, {:query => "*", :duration => 0.7, :force => :strong, :offset => {:x => x_offset, :y => 0}, :"swipe-delta" =>{:horizontal => {:dx => -1 * x_offset + 20, :dy => 0}}})
  wait_for_animations
  wait_for_view("* marked:'pan page'")
end

And(/^I swipe to delete the '(.*?)' table cell$/) do |cell_title|
  cell_query = "UILabel marked:'#{cell_title}'"
  wait_for_view(cell_query) 
  x_offset = query(cell_query)[0]["rect"]["width"] / 2.5
  swipe(:left, {:query => cell_query, :duration => 0.5, :force => :strong, :offset => {:x => x_offset, :y => 0}})
  wait_for_animations
  touch("UIButton marked:'Delete'")
end

Then(/^I no longer see the '(.*?)' table cell$/) do |cell_title|
  wait_for_animations
  if !query("UILabel marked:'#{cell_title}'").empty?
    fail "Table cell marked: #{cell_title} still exists"
  end
end
