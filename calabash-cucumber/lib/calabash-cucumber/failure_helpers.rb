require 'fileutils'

module Calabash
  module Cucumber

    # A collection of methods that help you handle Step failures.
    module FailureHelpers
      # FastImage Resize is a solution for resizing images in ruby by using libgd
      # it should be installed manually since it not required by calabash
      begin
        require "fastimage_resize"
      rescue LoadError
        # We just won't get error
      end

      # Generates a screenshot of the app UI and saves to a file (prefer `screenshot_embed`).
      # Increments a global counter of screenshots and adds the count to the filename (to ensure uniqueness).
      #
      # @see #screenshot_embed
      # @param {Hash} options to control the details of where the screenshot is stored.
      # @option options {String} :prefix (ENV['SCREENSHOT_PATH']) a prefix to prepend to the filename (e.g. 'screenshots/foo-').
      #   Uses ENV['SCREENSHOT_PATH'] if nil or '' if ENV['SCREENSHOT_PATH'] is nil
      # @option options {String} :name ('screenshot') the base name and extension of the file (e.g. 'login.png')
      # @return {String} path to the generated screenshot
      # @todo deprecated the current behavior of SCREENSHOT_PATH; it is confusing
      def screenshot(options={:prefix => nil, :name => nil, :scale => nil})
        prefix = options[:prefix]
        name = options[:name]
        scale = options[:scale]

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
        if defined?(FastImage)
          unless scale.nil?
            if scale != 1 and scale < 1 and scale > 0
              weight = FastImage.size(path)[0]
              FastImage.resize(path, weight/scale, 0, :outfile=>path)
            end
          end
        end
        @@screenshot_count += 1
        path
      end

      # Generates a screenshot of the app UI and embeds the screenshots in all active cucumber reporters (using `embed`).
      # Increments a global counter of screenshots and adds the count to the filename (to ensure uniqueness).
      #
      # @param {Hash} options to control the details of where the screenshot is stored.
      # @option options {String} :prefix (ENV['SCREENSHOT_PATH']) a prefix to prepend to the filename (e.g. 'screenshots/foo-').
      #   Uses ENV['SCREENSHOT_PATH'] if nil or '' if ENV['SCREENSHOT_PATH'] is nil
      # @option options {String} :name ('screenshot') the base name and extension of the file (e.g. 'login.png')
      # @option options {String} :label (uses filename) the label to use in the Cucumber reporters
      # @return {String} path to the generated screenshot
      def screenshot_embed(options={:prefix => nil, :name => nil, :label => nil})
        path = screenshot(options)
        filename = options[:label] || File.basename(path)
        if self.respond_to?(:embed)
          embed(path, 'image/png', filename)
        else
          RunLoop.log_info2("Embed is not available in this context. Will not embed.")
        end
        true
      end

      # Generates a screenshot of the app UI by calling screenshot_embed and raises an error.
      # Increments a global counter of screenshots and adds the count to the filename (to ensure uniqueness).
      #
      # @see #screenshot_embed
      # @param {String} msg the message to use for the raised RuntimeError.
      # @param {Hash} options to control the details of where the screenshot is stored.
      # @option options {String} :prefix (ENV['SCREENSHOT_PATH']) a prefix to prepend to the filename (e.g. 'screenshots/foo-').
      #   Uses ENV['SCREENSHOT_PATH'] if nil or '' if ENV['SCREENSHOT_PATH'] is nil
      # @option options {String} :name ('screenshot') the base name and extension of the file (e.g. 'login.png')
      # @option options {String} :label (uses filename) the label to use in the Cucumber reporters
      # @raise [RuntimeError] with `msg`
      def screenshot_and_raise(msg, options={:prefix => nil, :name => nil, :label => nil})
        screenshot_embed(options)
        raise(msg)
      end

      # Calls `screenshot_and_raise(msg,options)`
      # @see #screenshot_and_raise
      # @param {String} msg the message to use for the raised RuntimeError.
      # @param {Hash} options to control the details of where the screenshot is stored.
      # @option options {String} :prefix (ENV['SCREENSHOT_PATH']) a prefix to prepend to the filename (e.g. 'screenshots/foo-').
      #   Uses ENV['SCREENSHOT_PATH'] if nil or '' if ENV['SCREENSHOT_PATH'] is nil
      # @option options {String} :name ('screenshot') the base name and extension of the file (e.g. 'login.png')
      # @option options {String} :label (uses filename) the label to use in the Cucumber reporters
      # @raise [RuntimeError] with `msg`
      def fail(msg='Error. Check log for details.', options={:prefix => nil, :name => nil, :label => nil})
        screenshot_and_raise(msg, options)
      end
    end
  end
end
