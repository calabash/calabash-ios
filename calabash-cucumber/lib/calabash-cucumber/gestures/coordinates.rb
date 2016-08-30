
module Calabash
  module Cucumber
    module Gestures
      # @!visibility private
      class Coordinates

        require "calabash-cucumber/map"

        require "calabash-cucumber/status_bar_helpers"
        include Calabash::Cucumber::StatusBarHelpers

        # @!visibility private
        attr_reader :element

        # @!visibility private
        def initialize(element)
          @element = element
        end

        # @!visibility private
        def self.left_point_for_full_screen_pan
          coordinates = Coordinates.instance_without_element
          {
            x: coordinates.send(:min_x),
            y: coordinates.send(:window)[:center_y]
          }
        end

        # @!visibility private
        def self.right_point_for_full_screen_pan
          coordinates = Coordinates.instance_without_element
          {
            x: coordinates.send(:max_x),
            y: coordinates.send(:window)[:center_y]
          }
        end

        # @!visibility private
        def self.top_point_for_full_screen_pan
          coordinates = Coordinates.instance_without_element
          {
            x: coordinates.send(:window)[:center_x],
            y: coordinates.send(:min_y)
          }
        end

        # @!visibility private
        def self.bottom_point_for_full_screen_pan
          coordinates = Coordinates.instance_without_element
          {
            x: coordinates.send(:window)[:center_x],
            y: coordinates.send(:max_y)
          }
        end

        # @!visibility private
        def self.points_for_full_screen_pan(direction)
          case direction
            when :left
              start_point = Coordinates.right_point_for_full_screen_pan
              end_point = Coordinates.left_point_for_full_screen_pan
            when :right
              start_point = Coordinates.left_point_for_full_screen_pan
              end_point = Coordinates.right_point_for_full_screen_pan
            when :up
              start_point = Coordinates.bottom_point_for_full_screen_pan
              end_point = Coordinates.top_point_for_full_screen_pan
            when :down
              start_point = Coordinates.top_point_for_full_screen_pan
              end_point = Coordinates.bottom_point_for_full_screen_pan
            else
              raise ArgumentError,
                    "Direction #{direction} is not supported; use :left, :right, :top, :bottom"

          end

          {
            start: start_point,
            end: end_point
          }
        end

        # @!visibility private
        def left_point_for_full_view_pan
          {
            x: [min_x, element_origin[:x] + 10].max,
            y: element_center[:y]
          }
        end

        # @!visibility private
        def right_point_for_full_view_pan
          {
            x: [max_x, element_origin[:x] + element_size[:width] - 10].min,
            y: element_center[:y]
          }
        end

        # @!visibility private
        def top_point_for_full_view_pan
          {
            x: element_center[:x],
            y: [min_y, (element_origin[:y] + 10)].max
          }
        end

        # @!visibility private
        def bottom_point_for_full_view_pan
          {
            x: element_center[:x],
            y: [max_y, (element_origin[:y] + element_size[:height] - 10)].min
          }
        end

        # @!visibility private
        def points_for_full_view_pan(direction)
          case direction
            when :left
              start_point = right_point_for_full_view_pan
              end_point = left_point_for_full_view_pan
            when :right
              start_point = left_point_for_full_view_pan
              end_point = right_point_for_full_view_pan
            when :up
              start_point = bottom_point_for_full_view_pan
              end_point = top_point_for_full_view_pan
            when :down
              start_point = top_point_for_full_view_pan
              end_point = bottom_point_for_full_view_pan
            else
              raise ArgumentError,
                    "Direction #{direction} is not supported; use :left, :right, :top, :bottom"

          end

          {
            start: start_point,
            end: end_point
          }
        end

        # @!visibility private
        def left_point_for_half_view_pan
          {
            x: [min_x, element_center[:x] - (element_size[:width]/4.0)].max,
            y: element_center[:y]
          }
        end

        # @!visibility private
        def right_point_for_half_view_pan
          {
            x: [max_x, element_center[:x] + (element_size[:width]/4.0)].min,
            y: element_center[:y]
          }
        end

        # @!visibility private
        def top_point_for_half_view_pan
          {
            x: element_center[:x],
            y: [min_y, element_center[:y] - (element_size[:height]/4.0)].max
          }
        end

        # @!visibility private
        def bottom_point_for_half_view_pan
          {
            x: element_center[:x],
            y: [max_y, element_center[:y] + (element_size[:height]/4.0)].min
          }
        end

        # @!visibility private
        def points_for_half_view_pan(direction)
          case direction
            when :left
              start_point = right_point_for_half_view_pan
              end_point = left_point_for_half_view_pan
            when :right
              start_point = left_point_for_half_view_pan
              end_point = right_point_for_half_view_pan
            when :up
              start_point = bottom_point_for_half_view_pan
              end_point = top_point_for_half_view_pan
            when :down
              start_point = top_point_for_half_view_pan
              end_point = bottom_point_for_half_view_pan
            else
              raise ArgumentError,
                    "Direction #{direction} is not supported; use :left, :right, :top, :bottom"

          end

          {
            start: start_point,
            end: end_point
          }
        end

        # @!visibility private
        def left_point_for_small_view_pan
          {
            x: [min_x, element_center[:x] - (element_size[:width]/6.0)].max,
            y: element_center[:y]
          }
        end

        # @!visibility private
        def right_point_for_small_view_pan
          {
            x: [max_x, element_center[:x] + (element_size[:width]/6.0)].min,
            y: element_center[:y]
          }
        end

        # @!visibility private
        def top_point_for_small_view_pan
          {
            x: element_center[:x],
            y: [min_y, element_center[:y] - (element_size[:height]/6.0)].max
          }
        end

        # @!visibility private
        def bottom_point_for_small_view_pan
          {
            x: element_center[:x],
            y: [max_y, element_center[:y] + (element_size[:height]/6.0)].min
          }
        end

        # @!visibility private
        def points_for_small_view_pan(direction)
          case direction
            when :left
              start_point = right_point_for_small_view_pan
              end_point = left_point_for_small_view_pan
            when :right
              start_point = left_point_for_small_view_pan
              end_point = right_point_for_small_view_pan
            when :up
              start_point = bottom_point_for_small_view_pan
              end_point = top_point_for_small_view_pan
            when :down
              start_point = top_point_for_small_view_pan
              end_point = bottom_point_for_small_view_pan
            else
              raise ArgumentError,
                    "Direction #{direction} is not supported; use :left, :right, :top, :bottom"

          end

          {
            start: start_point,
            end: end_point
          }
        end

        # @!visibility private
        def self.end_point_for_swipe(dir, element, force)
          case dir
            when :left
              degrees = 0
            when :up
              degrees = 90
            when :right
              degrees = 180
            when :down
              degrees = 270
          end
          radians = degrees * Math::PI / 180.0

          case force
          when :light
            scale_radius_by = 0.25
          when :normal
            scale_radius_by = 0.333
          when :strong
            scale_radius_by = 0.5
          end

          element_width = element["rect"]["width"]
          element_height = element["rect"]["height"]
          x_center = element["rect"]["center_x"]
          y_center = element["rect"]["center_y"]
          radius = ([element_width, element_height].min) * scale_radius_by
          to_x = x_center + (radius * Math.cos(radians))
          to_y = y_center + (radius * Math.sin(radians))
          { :x => to_x, :y => to_y }
        end

        private

        # @!visibility private
        def self.instance_without_element
          Coordinates.new(nil)
        end

        # @!visibility private
        def element_center
          @element_center ||= begin
            {
              x: element["rect"]["center_x"],
              y: element["rect"]["center_y"]
            }
          end
        end

        # @!visibility private
        def element_origin
          @element_origin ||= begin
            {
              x: element["rect"]["x"],
              y: element["rect"]["y"]
            }
          end
        end

        # @!visibility private
        def element_size
          @element_size ||= begin
            {
              height: element["rect"]["height"],
              width: element["rect"]["width"]
            }
          end
        end

        # @!visibility private
        def query_wrapper(query, *args)
          Calabash::Cucumber::Map.map(query, :query, *args)
        end

        # @!visibility private
        def height_for_view(view_class)
          element = query_wrapper(view_class).first
          if element
            element["rect"]["height"]
          else
            0
          end
        end

        # @!visibility private
        def status_bar_height
          @status_bar_height ||= status_bar_details["frame"]["height"]
        end

        # @!visibility private
        def nav_bar_height
          @nav_bar_height ||= height_for_view("UINavigationBar")
        end

        # @!visibility private
        def tab_bar_height
          @tab_bar_height ||= height_for_view("UITabBar")
        end

        # @!visibility private
        def toolbar_height
          @toolbar_height ||= height_for_view("UIToolbar")
        end

        # @!visibility private
        def window
          @window ||= begin
            element = query_wrapper("*").first
            {
              :height => element["rect"]["height"],
              :width => element["rect"]["width"],
              :center_x => element["rect"]["center_x"],
              :center_y => element["rect"]["center_y"]
            }
          end
        end

        # @!visibility private
        def min_y
          @min_y ||= status_bar_height + nav_bar_height + 16
        end

        # @!visibility private
        def max_y
          @max_y ||= window[:height] - (tab_bar_height + toolbar_height + 16)
        end

        # @!visibility private
        def min_x
          10
        end

        # @!visibility private
        def max_x
          @max_x ||= window[:width] - 10
        end
      end
    end
  end
end
