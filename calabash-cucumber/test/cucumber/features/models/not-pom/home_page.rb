module NotPOM
  class HomePage
    include Calabash::Cucumber::Operations

    def my_buggy_method
      screenshot_and_raise 'Hey!'
    end

  end
end
