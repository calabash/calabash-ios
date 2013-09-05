require 'calabash-cucumber/launcher'
require 'calabash-cucumber/uia'


module Calabash
  module Cucumber
    module IOS7Operations
      include Calabash::Cucumber::UIA

      def ios7?
        launcher = @calabash_launcher || Calabash::Cucumber::Launcher.launcher_if_used
        ENV['OS']=='ios7' || (launcher && launcher.device.ios7?)
      end

      def touch_ios7(options)
        ui_query = options[:query]
        offset =  options[:offset]
        if ui_query.nil?
          uia_tap_offset(offset)
        else
          results = query(ui_query)
          if results.empty?
            screenshot_and_raise "Unable to find element matching query #{ui_query}"
          else
            el_to_touch = results.first
            touch(el_to_touch, options)
            [el_to_touch]
          end
        end
      end



    end
  end
end
