# @!visibility private
module Calabash
  module Cucumber
    module Gestures

      require "calabash-cucumber/gestures/performer"

      # @!visibility private
      class DeviceAgent < Calabash::Cucumber::Gestures::Performer

        require "run_loop"
        require "calabash-cucumber/map"

        require "calabash-cucumber/query_helpers"
        include Calabash::Cucumber::QueryHelpers

        require "calabash-cucumber/status_bar_helpers"
        include Calabash::Cucumber::StatusBarHelpers

        require "calabash-cucumber/rotation_helpers"
        include Calabash::Cucumber::RotationHelpers

        # @!visibility private
        def self.expect_valid_args(args)
          if args.nil?
            raise ArgumentError, "Expected args to be a non-nil Array"
          end

          if !args.is_a?(Array)
            raise ArgumentError, %Q[Expected args to be an Array, found:

args = #{args}

]
          end

          if args.count != 1
            raise(ArgumentError,
                  %Q[Expected args to be an Array with one element, found:

args = #{args}

])
          end

          if !args[0].is_a?(RunLoop::XCUITest)
            raise(ArgumentError,
                  %Q[Expected first element of args to be a RunLoop::XCUITest instance, found:

args[0] = #{args[0]}

])
          end

          true
        end

        # @!visibility private
        def self.name
          :device_agent
        end

        attr_reader :device_agent

        # @!visibility private
        def initialize(*args)
          DeviceAgent.expect_valid_args(args)
          @device_agent = args[0]
        end

        # @!visibility private
        def touch(options)
          hash = query_for_coordinates(options)

          device_agent.perform_coordinate_gesture("touch",
                                                  hash[:coordinates][:x],
                                                  hash[:coordinates][:y])
          [hash[:view]]
        end

        # @!visibility private
        def rotate(direction)
          # Caller is responsible for normalizing and verifying direction.
          current_orientation = status_bar_orientation.to_sym
          key = orientation_key(direction, current_orientation)
          position = orientation_for_key(key)
          rotate_home_button_to(position)
        end

        # @!visibility private
        def rotate_home_button_to(position)
          # Caller is responsible for normalizing and verifying position.
          @device_agent.rotate_home_button_to(position)
          status_bar_orientation.to_sym
        end

        private

        # @!visibility private
        def query_for_coordinates(options)
          ui_query = options[:query]

          first_element = first_element_for_query(ui_query)

          if first_element.nil?
            msg = %Q[
Could not find any views with query:

#{ui_query}

Try adjusting your query to return at least one view.

]
            Calabash::Cucumber::Map.new.screenshot_and_raise(msg)
          else
            {
              :coordinates => point_from(first_element),
              :view => first_element
            }
          end
        end

        # @!visibility private
        def first_element_for_query(ui_query)
          # Will raise if response "outcome" is not SUCCESS
          results = Calabash::Cucumber::Map.raw_map(ui_query, :query)["results"]

          if results.empty?
            nil
          else
            results[0]
          end
        end
      end
    end
  end
end
