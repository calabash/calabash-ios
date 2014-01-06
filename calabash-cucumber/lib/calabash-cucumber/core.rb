require 'httpclient'
require 'json'
require 'geocoder'
require 'calabash-cucumber/uia'
require 'calabash-cucumber/environment_helpers'
require 'calabash-cucumber/connection'
require 'calabash-cucumber/connection_helpers'
require 'calabash-cucumber/launch/simulator_helper'
require 'calabash-cucumber/query_helpers'
require 'calabash-cucumber/playback_helpers'
require 'calabash-cucumber/failure_helpers'
require 'calabash-cucumber/status_bar_helpers'
require 'calabash-cucumber/rotation_helpers'
require 'calabash-cucumber/map'

module Calabash
  module Cucumber
    module Core
      include Calabash::Cucumber::EnvironmentHelpers
      include Calabash::Cucumber::ConnectionHelpers
      include Calabash::Cucumber::QueryHelpers
      include Calabash::Cucumber::FailureHelpers
      include Calabash::Cucumber::Map
      include Calabash::Cucumber::UIA
      include Calabash::Cucumber::StatusBarHelpers
      include Calabash::Cucumber::RotationHelpers
      include Calabash::Cucumber::PlaybackHelpers


      def macro(txt)
        if self.respond_to? :step
          step(txt)
        else
          Then txt
        end
      end

      def query(uiquery, *args)
        map(uiquery, :query, *args)
      end

      def flash(uiquery, *args)
        map(uiquery, :flash, *args)
      end

      def server_version
        JSON.parse(http(:path => 'version'))
      end

      def client_version
        Calabash::Cucumber::VERSION
      end

      def query_all(uiquery, *args)
        msg0 = "use the 'all' or 'visible' query language feature"
        msg1 = 'see: https://github.com/calabash/calabash-ios/wiki/05-Query-syntax'
        msg = "#{msg0}\n#{msg1}"
        _deprecated('0.9.133', msg, :warn)
        map("all #{uiquery}", :query, *args)
      end

      def touch(uiquery, options={})
        query_action_with_options(:touch, uiquery, options)
      end

      def double_tap(uiquery, options={})
        query_action_with_options(:double_tap, uiquery, options)
      end

      def two_finger_tap(uiquery,options={})
        query_action_with_options(:two_finger_tap, uiquery, options)
      end

      def flick(uiquery, delta, options={})
        uiquery, options = extract_query_and_options(uiquery, options)
        options[:delta] = delta
        views_touched = launcher.actions.flick(options)
        unless uiquery.nil?
          screenshot_and_raise "flick could not find view: '#{uiquery}', args: #{options}" if views_touched.empty?
        end
        views_touched
      end

      def touch_hold(uiquery, options={})
        query_action_with_options(:touch_hold, uiquery, options)
      end

      def swipe(dir, options={})
        unless uia_available?
          options = options.merge(:status_bar_orientation => status_bar_orientation)
        end
        launcher.actions.swipe(dir.to_sym, options)
      end

      def pan(from, to, options={})
        launcher.actions.pan(from, to, options)
      end

      def pinch(in_out, options={})
        launcher.actions.pinch(in_out.to_sym,options)
      end


      def cell_swipe(options={})
        if uia_available?
          raise 'cell_swipe not supported with instruments, simply use swipe with a query that matches the cell'
        end
        playback('cell_swipe', options)
      end

      def scroll(uiquery, direction)
        views_touched=map(uiquery, :scroll, direction)
        screenshot_and_raise "could not find view to scroll: '#{uiquery}', args: #{direction}" if views_touched.empty?
        views_touched
      end

      def scroll_to_row(uiquery, number)
        views_touched=map(uiquery, :scrollToRow, number)
        if views_touched.empty? or views_touched.member? '<VOID>'
          screenshot_and_raise "Unable to scroll: '#{uiquery}' to: #{number}"
        end
        views_touched
      end

      def scroll_to_cell(options={:query => 'tableView',
                                  :row => 0,
                                  :section => 0,
                                  :scroll_position => :top,
                                  :animate => true})
        uiquery = options[:query] || 'tableView'
        row = options[:row]
        sec = options[:section]
        if row.nil? or sec.nil?
          raise 'You must supply both :row and :section keys to scroll_to_cell'
        end

        args = []
        if options.has_key?(:scroll_position)
          args << options[:scroll_position]
        else
          args << 'top'
        end
        if options.has_key?(:animate)
          args << options[:animate]
        end
        views_touched=map(uiquery, :scrollToRow, row.to_i, sec.to_i, *args)

        if views_touched.empty? or views_touched.member? '<VOID>'
          screenshot_and_raise "Unable to scroll: '#{uiquery}' to: #{options}"
        end
        views_touched
      end


      def scroll_to_row_with_mark(row_id, options={:query => 'tableView',
                                                   :scroll_position => :middle,
                                                   :animate => true})
        uiquery = options[:query] || 'tableView'

        args = []
        if options.has_key?(:scroll_position)
          args << options[:scroll_position]
        else
          args << 'middle'
        end
        if options.has_key?(:animate)
          args << options[:animate]
        end

        views_touched=map(uiquery, :scrollToRowWithMark, row_id, *args)

        if views_touched.empty? or views_touched.member? '<VOID>'
          msg = options[:failed_message] || "Unable to scroll: '#{uiquery}' to: #{options}"
          screenshot_and_raise msg
        end
        views_touched
      end

      def send_app_to_background(secs)
        launcher.actions.send_app_to_background(secs)
      end

      def set_location(options)
        if uia_available?
          uia_set_location(options)
        else
          if options[:place]
            res = location_for_place(options[:place])
            lat = res.latitude
            lon = res.longitude
          else
            lat = options[:latitude]
            lon = options[:longitude]
          end
          body_data = {:action => :change_location,
                       :latitude => lat,
                       :longitude => lon}

          body = http({:method => :post, :path => 'location'}, body_data)

          res = JSON.parse(body)
          if res['outcome'] != 'SUCCESS'
            screenshot_and_raise "Set location change failed, for #{lat}, #{lon} (#{body})."
          end
          res['results']

        end
      end

      def location_for_place(place)
        search_results = locations_for_place(place)
        raise "Got no results for #{place}" if search_results.empty?
        search_results.first
      end

      def locations_for_place(place)
        Geocoder.search(place)
      end

      def move_wheel(opts={})
        q = opts[:query] || 'pickerView'
        wheel = opts[:wheel] || 0
        dir = opts[:dir] || :down

        raise 'Wheel index must be non negative' if wheel < 0
        raise "Only up and down supported :dir (#{dir})" unless [:up, :down].include?(dir)

        if ENV['OS'] == 'ios4'
          playback "wheel_#{dir}", :query => "#{q} pickerTable index:#{wheel}"
        elsif ios7?
          raise NotImplementedError
        else
          playback "wheel_#{dir}", :query => "#{q} pickerTableView index:#{wheel}"
        end

      end

      def picker(opts={:query => 'pickerView', :action => :texts})
        raise 'Not implemented' unless opts[:action] == :texts

        q = opts[:query]

        check_element_exists(q)

        comps = query(q, :numberOfComponents).first
        row_counts = []
        texts = []
        comps.times do |i|
          row_counts[i] = query(q, :numberOfRowsInComponent => i).first
          texts[i] = []
        end

        row_counts.each_with_index do |row_count, comp|
          row_count.times do |i|
            #view = query(q,[{:viewForRow => 0}, {:forComponent => 0}],:accessibilityLabel).first
            spec = [{:viewForRow => i}, {:forComponent => comp}]
            view = query(q, spec).first
            if view
              txt = query(q, spec, :accessibilityLabel).first
            else
              txt = query(q, :delegate, [{:pickerView => :view},
                                         {:titleForRow => i},
                                         {:forComponent => comp}]).first
            end
            texts[comp] << txt
          end
        end
        texts
      end


      def backdoor(sel, arg)
        json = {
              :selector => sel,
              :arg => arg
        }
        res = http({:method => :post, :path => 'backdoor'}, json)
        res = JSON.parse(res)
        if res['outcome'] != 'SUCCESS'
          screenshot_and_raise "backdoor #{json} failed because: #{res['reason']}\n#{res['details']}"
        end
        res['result']
      end

      def calabash_exit
        # Exiting the app shuts down the HTTP connection and generates ECONNREFUSED,
        # or HTTPClient::KeepAliveDisconnected
        # which needs to be suppressed.
        begin
          http({:method => :post, :path => 'exit', :retryable_errors => Calabash::Cucumber::HTTPHelpers::RETRYABLE_ERRORS - [Errno::ECONNREFUSED, HTTPClient::KeepAliveDisconnected]})
        rescue Errno::ECONNREFUSED, HTTPClient::KeepAliveDisconnected
          []
        end
      end

      ## args :app for device bundle id, for sim path to app
      ##
      def start_test_server_in_background(args={})
        stop_test_server
        @calabash_launcher = Calabash::Cucumber::Launcher.new()
        @calabash_launcher.relaunch(args)
        @calabash_launcher
      end

      def stop_test_server
        l = @calabash_launcher || Calabash::Cucumber::Launcher.launcher_if_used
        l.stop if l
      end

      def shutdown_test_server
        # Compat with Calabash Android
        stop_test_server
      end


      def console_attach
        # setting the @calabash_launcher here for backward compatibility
        @calabash_launcher = launcher.attach
      end

      def launcher
        # setting the @calabash_launcher here for backward compatibility
        @calabash_launcher = Calabash::Cucumber::Launcher.launcher
      end

      def query_action_with_options(action, uiquery, options)
        uiquery, options = extract_query_and_options(uiquery, options)
        views_touched = launcher.actions.send(action, options)
        unless uiquery.nil?
          screenshot_and_raise "#{action} could not find view: '#{uiquery}', args: #{options}" if views_touched.empty?
        end
        views_touched
      end

      def extract_query_and_options(uiquery, options)
        options = prepare_query_options(uiquery, options)
        return options[:query], options
      end

      def prepare_query_options(uiquery, options)
        opts = options.dup
        if uiquery.is_a?(Array)
          raise 'No elements in array' if uiquery.empty?
          uiquery = uiquery.first
        end #this is deliberately not elsif (uiquery.first could be a hash)

        if uiquery.is_a?(Hash)
          opts[:offset] = point_from(uiquery, options)
          uiquery = nil
        end
        opts[:query] = uiquery
        opts
      end

    end
  end
end

