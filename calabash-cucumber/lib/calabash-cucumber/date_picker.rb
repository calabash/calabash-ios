require 'date'

module Calabash
  module Cucumber

    # A collection of methods for interacting with UIDatePicker
    module DatePicker
      include Calabash::Cucumber::Core

      # equivalent formats for ruby and objc
      # we convert DateTime object to a string
      # and pass the format that objc can use
      # to convert the string into NSDate

      # @!visibility private
      RUBY_DATE_AND_TIME_FMT = '%Y_%m_%d_%H_%M'

      # @!visibility private
      OBJC_DATE_AND_TIME_FMT = 'yyyy_MM_dd_HH_mm'

      # picker modes

      # @!visibility private
      UI_DATE_PICKER_MODE_TIME = 0
      # @!visibility private
      UI_DATE_PICKER_MODE_DATE = 1
      # @!visibility private
      UI_DATE_PICKER_MODE_DATE_AND_TIME = 2
      # @!visibility private
      UI_DATE_PICKER_MODE_COUNT_DOWN_TIMER = 3

      # @!visibility private
      # Returns the picker mode of the UIDatePicker.
      #
      # @see #time_mode?
      # @see #date_mode?
      # @see #date_and_time_mode?
      # @see #countdown_mode?
      #
      # @param [String] picker_id The accessibility label or id of the picker
      #  you are looking for.  If nil, then the first UIDatePicker that is
      #  found will be queried.
      # @return [String] Returns the picker mode which will be one of
      #  `{'0', '1', '2', '3'}`
      # @raise [RuntimeError] if no picker can be found
      def date_picker_mode(picker_id=nil)
        query_str = should_see_date_picker picker_id
        res = query(query_str, :datePickerMode)
        if res.empty?
          screenshot_and_raise "should be able to get mode from picker with query '#{query_str}'"
        end
        res.first
      end

      # Is the date picker in time mode?
      #
      # @see #time_mode?
      # @see #date_mode?
      # @see #date_and_time_mode?
      # @see #countdown_mode?
      #
      # @param [String] picker_id The accessibility label or id of the picker
      #  you are looking for.  If nil, then the first UIDatePicker that is
      #  found will be queried.
      # @return [Boolean] true if the picker is in time mode
      # @raise [RuntimeError] if no picker can be found
      def time_mode?(picker_id=nil)
        date_picker_mode(picker_id) == UI_DATE_PICKER_MODE_TIME
      end

      # Is the date picker in date mode?
      #
      # @see #time_mode?
      # @see #date_mode?
      # @see #date_and_time_mode?
      # @see #countdown_mode?
      #
      # @param [String] picker_id The accessibility label or id of the picker
      #  you are looking for.  If nil, then the first UIDatePicker that is
      #  found will be queried.
      # @return [Boolean] true if the picker is in date mode
      # @raise [RuntimeError] if no picker can be found
      def date_mode?(picker_id=nil)
        date_picker_mode(picker_id) == UI_DATE_PICKER_MODE_DATE
      end

      # Is the date picker in date and time mode?
      #
      # @see #time_mode?
      # @see #date_mode?
      # @see #date_and_time_mode?
      # @see #countdown_mode?
      #
      # @param [String] picker_id The accessibility label or id of the picker
      #  you are looking for.  If nil, then the first UIDatePicker that is
      #  found will be queried.
      # @return [Boolean] true if the picker is in date and time mode
      # @raise [RuntimeError] if no picker can be found
      def date_and_time_mode?(picker_id=nil)
        date_picker_mode(picker_id) == UI_DATE_PICKER_MODE_DATE_AND_TIME
      end

      # Is the date picker in countdown mode?
      #
      # @see #time_mode?
      # @see #date_mode?
      # @see #date_and_time_mode?
      # @see #countdown_mode?
      #
      # @param [String] picker_id The accessibility label or id of the picker
      #  you are looking for.  If nil, then the first UIDatePicker that is
      #  found will be queried.
      # @return [Boolean] true if the picker is in countdown mode
      # @raise [RuntimeError] if no picker can be found
      def countdown_mode?(picker_id=nil)
        date_picker_mode(picker_id) == UI_DATE_PICKER_MODE_COUNT_DOWN_TIMER
      end

      # @!visibility private
      # Returns a query string for a date picker.
      #
      # @param [String] picker_id The accessibility label or id of the picker
      #  you are looking for.  If nil, a query that looks for any UIDatePicker
      #  will be constructed.
      # @return [String] a query-ready string for finding a UIDatePicker
      def query_string_for_picker (picker_id = nil)
        picker_id.nil? ? 'datePicker' : "datePicker marked:'#{picker_id}'"
      end

      # Asserts that a date picker is visible.
      #
      # @param [String] picker_id The accessibility label or id of the picker
      #  you are looking for.  If nil, any visible date picker will satisfy the
      #  assertion.
      # @raise [RuntimeError] if a matching date picker is not visible
      def should_see_date_picker (picker_id=nil)
        query_str = query_string_for_picker picker_id
        if query(query_str).empty?
          screenshot_and_raise "should see picker with query '#{query_str}'"
        end
        query_str
      end

      # The maximum date for a picker.  If there is no maximum date, this
      # method returns nil.
      #
      # @note
      #  From the Apple docs:
      #  `The property is an NSDate object or nil (the default)`.
      #
      # @param [String] picker_id The accessibility label or id of the picker
      #  you are looking for.  If nil, then the first UIDatePicker that is
      #  found will be queried.
      # @return [DateTime] the maximum date on the picker or nil if no maximum
      #  exists
      # @raise [RuntimeError] if the picker is in countdown mode
      # @raise [RuntimeError] if the picker cannot be found
      def maximum_date_time_from_picker (picker_id = nil)
        if countdown_mode? picker_id
          screenshot_and_raise 'method is not available for pickers that are not in date or date time mode'
        end

        query_str = should_see_date_picker picker_id
        res = query(query_str, :maximumDate)
        if res.empty?
          screenshot_and_raise "should be able to get max date from picker with query '#{query_str}'"
        end
        return nil if res.first.nil?
        DateTime.parse(res.first)
      end

      # The minimum date for a picker.  If there is no minimum date, this
      # method returns nil.
      #
      # @note
      #  From the Apple docs:
      #  `The property is an NSDate object or nil (the default)`.
      #
      # @param [String] picker_id The accessibility label or id of the picker
      #  you are looking for.  If nil, then the first UIDatePicker that is
      #  found will be queried.
      # @return [DateTime] the minimum date on the picker or nil if no minimum
      #  exists
      # @raise [RuntimeError] if the picker is in countdown mode
      # @raise [RuntimeError] if the picker cannot be found
      def minimum_date_time_from_picker (picker_id = nil)
        if countdown_mode? picker_id
          screenshot_and_raise 'method is not available for pickers that are not in date or date time mode'
        end

        query_str = should_see_date_picker picker_id
        res = query(query_str, :minimumDate)
        if res.empty?
          screenshot_and_raise "should be able to get min date from picker with query '#{query_str}'"
        end
        return nil if res.first.nil?
        DateTime.parse(res.first)
      end

      # Returns the date and time from the picker.
      #
      # @param [String] picker_id The accessibility label or id of the picker
      #  you are looking for.  If nil, then the first UIDatePicker that is
      #  found will be queried.
      # @return [DateTime] the date on the picker
      # @raise [RuntimeError] if the picker is in countdown mode
      # @raise [RuntimeError] if the picker cannot be found
      def date_time_from_picker (picker_id=nil)
        if countdown_mode? picker_id
          screenshot_and_raise 'method is not available for pickers that are not in date or date time mode'
        end
        query_str = query_string_for_picker picker_id
        res = query(query_str, :date)
        if res.empty?
          screenshot_and_raise "should be able to get date from picker with query '#{query_str}'"
        end
        DateTime.parse(res.first)
      end

      # @!visibility private
      # @todo replace with a `merge` inside the calling function
      # -1 @jmoody for ruby noob-ness
      def args_for_change_date_on_picker(options)
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

      # Sets the date and time on picker.
      #
      # @note
      #  When `:notify_targets => true` this operation iterates through the
      #  target/action pairs on the objc `UIDatePicker` instance and calls
      # `performSelector:<action> object:<target>`.  This has the effect of
      #  generating `UIEvents`.
      #
      # @param [DateTime] target_dt the date and time you want to change to
      # @param [Hash] options controls the behavior of this method
      # @option options [Boolean] :animate (true) animate the date change
      # @option options [String]  :picker_id (nil) The accessibility id or label
      #  of the date picker you are looking for.  If nil, the first UIDatePicker
      #  that is found will have the date and time applied.
      # @option options [Boolean] :notify_target (true) If true, all the date
      #  picker's target/action pairs will be called.  This is necessary to
      #  generate UIEvents.  If false, no UIEvents will be generated and it is
      #  likely that your UI will not update correctly.
      #
      # @raise [RuntimeError] if no date picker can be found
      # @raise [RuntimeError] if the target date is greater than the picker's
      #  maximum date
      # @raise [RuntimeError] if the target date is less than the picker's
      #  minimum date
      # @raise [RuntimeError] if the target date is not a DateTime instance
      # @todo replace `args_for_change_date_on_picker` with hash table `merge`
      def picker_set_date_time (target_dt, options = {:animate => true,
                                                      :picker_id => nil,
                                                      :notify_targets => true})
        unless target_dt.is_a?(DateTime)
          raise "target_dt must be a DateTime but found '#{target_dt.class}'"
        end

        picker_id = options == nil ? nil : options[:picker_id]

        if time_mode?(picker_id) == UI_DATE_PICKER_MODE_COUNT_DOWN_TIMER
          pending('picker is in count down mode which is not yet supported')
        end

        target_str = target_dt.strftime(RUBY_DATE_AND_TIME_FMT).squeeze(' ').strip
        fmt_str = OBJC_DATE_AND_TIME_FMT

        args = args_for_change_date_on_picker options
        query_str = query_string_for_picker picker_id

        views_touched = fetch_results(query_str, :changeDatePickerDate, target_str, fmt_str, *args)
        msg = "could not change date on picker to '#{target_dt}' using query '#{query_str}' with options '#{options}'"
        assert_map_results(views_touched,msg)
        views_touched
      end
    end
  end
end
