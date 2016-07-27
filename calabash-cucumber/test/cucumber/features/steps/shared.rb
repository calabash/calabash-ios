Given(/^the app has launched$/) do
  wait_for do
    !query("*").empty?
  end
end

Given(/^I am looking at the (Touch|Pan|Rotate\/Pinch|Misc|Tao) tab$/) do |tabname|
  query = "* marked:'#{tabname}'"
  wait_for_view(query)
  touch(query)
end
