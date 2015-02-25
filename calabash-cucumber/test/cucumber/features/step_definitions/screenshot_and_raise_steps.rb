When(/^I use screenshot_and_raise in the context of cucumber$/) do
  begin
    screenshot_and_raise 'Hey!'
  rescue StandardError => e
    @screenshot_and_raise_exception = e
  end
end

Then(/^I should get a runtime exception$/) do
  if @screenshot_and_raise_exception.nil?
    raise 'Expected the previous step to raise an exception'
  end
end

When(/^I screenshot_and_raise outside the context of cucumber$/) do
  begin
    NotPOM::HomePage.new.my_exceptional_method
  rescue StandardError => e
    @screenshot_and_raise_exception = e
  end
end

But(/^it should not be a NoMethod exception for embed$/) do
  error = @screenshot_and_raise_exception
  is_a_no_method_error = error.is_a?(NoMethodError)

  if is_a_no_method_error
    raise "Expected '#{error}' not to be a NoMethodError"
  end
end
