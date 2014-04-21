require 'fileutils'

module Calabash
  module Cucumber
    module FailureHelpers

      def screenshot(options={:prefix => nil, :name => nil})
        prefix = options[:prefix]
        name = options[:name]

        @@screenshot_count ||= 0
        res = http({:method => :get, :path => 'screenshot'})
        prefix = prefix || ENV['SCREENSHOT_PATH'] || ''
        if name.nil?
          name = 'screenshot'
        else
          if File.extname(name).downcase == '.png'
            name = name.split('.png')[0]
          end
        end

        path = "#{prefix}#{name}_#{@@screenshot_count}.png"
        File.open(path, 'wb') do |f|
          f.write res
        end
        @@screenshot_count += 1
        path
      end

      def screenshot_embed(options={:prefix => nil, :name => nil, :label => nil})
        path = screenshot(options)
        filename = options[:label] || File.basename(path)
        embed(path, 'image/png', filename)
      end

      def screenshot_and_raise(msg, options={:prefix => nil, :name => nil, :label => nil})
        screenshot_embed(options)
        raise(msg)
      end

      def fail(msg='Error. Check log for details.', options={:prefix => nil, :name => nil, :label => nil})
        screenshot_and_raise(msg, options)
      end

    end
  end
end