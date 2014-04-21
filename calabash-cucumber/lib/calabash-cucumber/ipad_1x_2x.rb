require 'calabash-cucumber/environment_helpers'
require 'calabash-cucumber/query_helpers'
require 'calabash-cucumber/http_helpers'
require 'calabash-cucumber/failure_helpers'
require 'calabash-cucumber/uia'

module Calabash
  module Cucumber
    module IPad

      class Emulation
        include Calabash::Cucumber::FailureHelpers
        include Calabash::Cucumber::HTTPHelpers
        include Calabash::Cucumber::QueryHelpers
        include Calabash::Cucumber::UIA

        # NOTE to maintainers - when adding a localization, please notice that
        # the keys and values are semantically reversed.
        #
        # you should read the hash as:
        #
        #     :emulated_1x #=> what button is showing when the app is emulated at 2X?
        #     :emulated_2x #=> what button is showing when the app is emulated at 1X?
        IPAD_1X_2X_BUTTON_LABELS = {
              :en => {:emulated_1x => '2X',
                      :emulated_2x => '1X'}
        }

        attr_reader :scale
        attr_reader :lang_code

        @button_names_hash = nil

        def initialize (lang_code=:en)
          @button_names_hash = IPAD_1X_2X_BUTTON_LABELS[lang_code]
          if @button_names_hash.nil?
            raise "could not find 1X/2X buttons for language code '#{lang_code}'"
          end

          @lang_code = lang_code
          @scale = _internal_ipad_emulation_scale
        end

        def tap_ipad_scale_button
          key = @scale
          name = @button_names_hash[key]

          res = uia_call_windows([:view, {:marked => "#{name}"}], :tap)

          # ':nil' is a very strange success return value...
          if res.is_a?(Hash) or res != ':nil'
            screenshot_and_raise "could not touch scale button '#{name}' - '#{res['value']}'"
          end
        end

        private
        def _internal_ipad_emulation_scale
          hash = @button_names_hash
          val = nil
          hash.values.each do |button_name|
            res = uia_call_windows([:view, {:marked => "#{button_name}"}], :name)

            if res == button_name
              val = button_name
              break
            end
          end

          if val.nil?
            raise "could not find iPad scale button with '#{hash.values}'"
          end

          if val == hash[:emulated_1x]
            :emulated_1x
          elsif val == hash[:emulated_2x]
            :emulated_2x
          else
            raise "unrecognized emulation scale '#{val}'"
          end
        end

      end

      # ensures that iPhone apps emulated on an iPad are displayed at +scale+.
      #
      # starting in iOS 7, iPhone apps emulated on the iPad always launch at 2x.
      # calabash cannot currently interact with such apps in 2x mode (trust us,
      # we've tried).
      #
      # +scale+ must be one of { +:emulated_1x+ | +:emulated_2x+ }
      #
      # is it is recommended that clients call this convenience method:
      #
      # +ensure_ipad_emulation_1x+ #=> ensures the app is displayed in 1x mode
      #
      # takes these optional arguments
      #
      #        :lang_code #=> a language code for matching the name of the 'scale' button
      # :wait_after_touch #=> how long to wait after the 'scale' button is touched
      #
      # the default values are:
      #
      #        :lang_code => :en
      # :wait_after_touch => 0.4
      #
      # +IMPORTANT+ if this is not an iphone app emulated on a ipad, then calling
      # this function has no effect.
      #
      # raises an exception if:
      # * the app was +not+ launched with Instruments i.e. there is no <tt>run_loop</tt>
      # * an invalid +scale+ is passed
      # * an unknown language code is passed
      # * the 'scale' button cannot be touched
      def ensure_ipad_emulation_scale(scale, opts={})
        return unless iphone_app_emulated_on_ipad?

        unless uia_available?
          raise 'this function requires the app be launched with instruments'
        end

        allowed = [:emulated_1x, :emulated_2x]
        unless allowed.include?(scale)
          raise "'#{scale}' is not one of '#{allowed}' allowed args"
        end

        default_opts = {:lang_code => :en,
                        :wait_after_touch => 0.4}
        merged_opts = default_opts.merge(opts)

        obj = Emulation.new(merged_opts[:lang_code])

        actual_scale = obj.scale

        if actual_scale != scale
          obj.tap_ipad_scale_button
        end

        sleep(merged_opts[:wait_after_touch])

      end

      # ensures that iPhone apps emulated on an iPad are displayed at +1X+.
      #
      # here is an example of how to use this function in your +Before+ launch
      # hooks:
      #
      #    Before do |scenario|
      #      @calabash_launcher = Calabash::Cucumber::Launcher.new
      #      unless @calabash_launcher.calabash_no_launch?
      #        @calabash_launcher.relaunch
      #        @calabash_launcher.calabash_notify(self)
      #        # ensure emulated apps are at 1x
      #        ensure_ipad_emulation_1x
      #      end
      #      # do other stuff to prepare the test environment
      #    end
      #
      # takes these optional arguments
      #
      #        :lang_code #=> a language code for matching the name of the 'scale' button
      # :wait_after_touch #=> how long to wait after the 'scale' button is touched
      #
      # the default values are:
      #
      #        :lang_code => :en
      # :wait_after_touch => 0.4
      #
      # +IMPORTANT+ if this is not an iphone app emulated on a ipad, then calling
      # this function has no effect.
      #
      # raises an exception if:
      # * the app was +not+ launched with Instruments i.e. there is no <tt>run_loop</tt>
      # * an unknown language code is passed
      # * the 'scale' button cannot be touched
      def ensure_ipad_emulation_1x(opts={})
        ensure_ipad_emulation_scale(:emulated_1x, opts)
      end

      private
      # ensures iPhone apps running on an iPad are emulated at 2X
      #
      # you should never need to call this function - calabash cannot interact
      # with iPhone apps emulated on the iPad in 2x mode.
      def _ensure_ipad_emulation_2x(opts={})
        ensure_ipad_emulation_scale(:emulated_2x, opts)
      end

    end
  end
end