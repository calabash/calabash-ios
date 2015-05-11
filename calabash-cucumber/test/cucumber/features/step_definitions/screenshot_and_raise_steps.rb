When(/^I use screenshot_and_raise in the context of cucumber$/) do
  begin
    screenshot_and_raise 'Hey!'
  rescue StandardError => e
    @screenshot_and_raise_error = e
  end
end

Then(/^I should get a runtime error$/) do
  if @screenshot_and_raise_error.nil?
    raise 'Expected the previous step to raise an error'
  end
end

When(/^I screenshot_and_raise outside the context of cucumber$/) do
  begin
    NotPOM::HomePage.new.my_buggy_method
  rescue StandardError => e
    @screenshot_and_raise_error = e
  end
end

But(/^it should not be a NoMethod error for embed$/) do
  error = @screenshot_and_raise_error
  is_a_no_method_error = error.is_a?(NoMethodError)

  if is_a_no_method_error
    raise "Expected '#{error}' not to be a NoMethodError"
  end
end
