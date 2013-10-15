module Calabash
  module Cucumber
    module Slider
      include Calabash::Cucumber::Core


      def args_for_slider_set_value(options)
        args = []
        if options.has_key?(:notify_targets)
          args << options[:notify_targets] ? 1 : 0
        else
          args << 1
        end

        if options.has_key?(:animate)
          args << options[:animate] ? 1 : 0
        else
          args << 1
        end
        args
      end

      def slider_set_value(slider_id, value,  options = {:animate => true,
                                                         :notify_targets => true})
        value_str = value.to_f.to_s
        args = args_for_slider_set_value(options)
        query_str =  "slider marked:'#{slider_id}'"
        views_touched = map(query_str, :changeSlider, value_str, *args)
        if views_touched.empty? or views_touched.member? '<VOID>'
          screenshot_and_raise "could not slider marked '#{slider_id}' to '#{value}' using query '#{query_str}' with options '#{options}'"
        end

        views_touched
      end

    end
  end
end
