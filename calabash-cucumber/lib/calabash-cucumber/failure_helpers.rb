require 'fileutils'

module Calabash
  module Cucumber
    module FailureHelpers

      # Generates a screenshot of the app UI and saves to a file (prefer `screenshot_embed`).
      # Increments a global counter of screenshots and adds the count to the filename (to ensure uniqueness).
      #
      # @see #screenshot_embed
      # @param {Hash} options to control the details of where the screenshot is stored.
      # @option options {String} :prefix (ENV['SCREENSHOT_PATH']) a prefix to prepend to the filename (e.g. 'screenshots/foo-').
      #   Uses ENV['SCREENSHOT_PATH'] if nil or '' if ENV['SCREENSHOT_PATH'] is nil
      # @option options {String} :name ('screenshot') the base name and extension of the file (e.g. 'login.png')
      # @return {String} path to the generated screenshot
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
        embed(path, 'image/png', filename)
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