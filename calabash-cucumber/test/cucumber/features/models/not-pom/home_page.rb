module NotPOM
  class HomePage
    include Calabash::Cucumber::Operations

    def my_exceptional_method
      screenshot_and_raise 'Hey!'
    end

  end
end
