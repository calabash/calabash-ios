module Calabash
  module Cucumber
    module StatusBarHelpers #=> Map

      def device_orientation(force_down=false)
        res = map(nil, :orientation, :device).first

        if ['face up', 'face down'].include?(res)
          if ENV['CALABASH_FULL_CONSOLE_OUTPUT'] == '1'
            if force_down
              puts "WARN  found orientation '#{res}' - will rotate to force orientation to 'down'"
            end
          end

          return res unless force_down
          return rotate_home_button_to :down
        end

        return res unless res.eql?('unknown')
        return res unless force_down
        rotate_home_button_to(:down)
      end

      def status_bar_orientation
        map(nil, :orientation, :status_bar).first
      end

      # returns +true+ if orientation is portrait
      def portrait?
        o = status_bar_orientation
        o.eql?('up') or o.eql?('down')
      end

      # returns +true+ if orientation is landscape
      def landscape?
        o = status_bar_orientation
        o.eql?('right') or o.eql?('left')
      end

    end
  end
end