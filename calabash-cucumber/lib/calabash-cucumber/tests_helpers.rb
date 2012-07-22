module Calabash
  module Cucumber
    module TestsHelpers

      def screenshot_and_raise(msg,prefix=nil,name=nil)
        screenshot(prefix,name)
        raise(msg)
      end

      def fail(msg="Error. Check log for details.",prefix=nil,name=nil)
        screenshot_and_raise(msg,prefix,name)
      end

      def screenshot(prefix=nil, name=nil)
        res = http({:method => :get, :path => 'screenshot'})
        prefix = prefix || ENV['SCREENSHOT_PATH'] || ""
        name = "screenshot_#{CALABASH_COUNT[:step_line]}.png" if name.nil?
        path = "#{prefix}#{name}"
        File.open(path, 'wb') do |f|
          f.write res
        end
        puts "Saved screenshot: #{path}"
        path
      end


    end
  end
end
