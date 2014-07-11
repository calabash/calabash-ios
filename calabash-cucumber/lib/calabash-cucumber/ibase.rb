require 'calabash-cucumber/core'
require 'calabash-cucumber/operations'

# The `IBase` class is a base class that can be used to easily implement page object classes on iOS (hence the I).
# Delegates to the cucumber World object for missing methods (e.g. embed or puts).
# Mixes in {Calabash::Cucumber::Operations}.
# For Calabash Android there is a corresponding `ABase`.
# For more detailed documentation on using the Page Object Pattern (POP) with Calabash, please see:
# {http://developer.xamarin.com/guides/testcloud/calabash/xplat-best-practices/}.
# Note we recommend using POP even if you're not targeting multiple platforms as it tends to lead to more maintainable
# test suites.
class Calabash::IBase
  include Calabash::Cucumber::Operations

  # @!attribute [rw] world
  #  @return [Object] the Cucumber World instance
  attr_accessor :world

  # @!attribute [rw] transition_duration
  #  @return [Number] the number of seconds to allow for page transitions
  attr_accessor :transition_duration

  # Create a new page object.
  #
  # @param [Object] world the cucumber World object
  # @param [Number] transition_duration the number of seconds to for page
  #  transitions
  def initialize(world, transition_duration=0.5)
    self.world = world
    self.transition_duration = transition_duration
  end

  # Specifies a query that recognizes this page.
  #
  # @abstract
  # @see #await
  #
  # In your subclass, you have two options to implement this abstract method.
  #
  # 1. Override the `trait` method.
  # 2. Implement a `title` method.
  #
  # If you implement a `title` method, this method will return:
  # `"navigationItemView marked:'#{self.title}'"`
  #
  # @note It is recommended that you override this method method in your in
  #  your subclasses (option 1 below).  Relying on the UINavigationBar title is
  #  risky because Apple's UINavigationBar API changes often.
  #
  # @example
  #  "view marked:'home'"
  #
  # @example
  #  "tableView marked:'playlist'"
  #
  # @example
  #  "button marked:'login'"
  #
  # @return [String] a query string that identifies this page
  # @raise [NotImplementedError] if the subclass does not respond to `title` or
  #  the subclass does not override the `trait` method
  def trait
    raise "You should define a trait method or a title method" unless respond_to?(:title)
    "navigationItemView marked:'#{self.title}'"
  end

  # returns true if the current view shows this page's `trait`
  # @see #trait
  # @return [Boolean] true iff `element_exists(trait)`
  def current_page?
    element_exists(trait)
  end

  # A variant of {Calabash::Cucumber::Core#page} that works inside page objects.
  # @see Calabash::Cucumber::Core#page
  # @see Calabash::IBase
  # @param {Class} clz the page object class to instantiate (passing the cucumber world and `args`)
  # @param {Array} args optional additional arguments to pass to the page object constructor
  # @return {Object} a fresh instance of `Class clz` which has been passed a reference to the cucumber World object.
  def page(clz, *args)
    clz.new(world, *args)
  end

  # Waits for this page to load. This is done by calling `wait_for_element_exists(trait, wait_opts)` and
  # optionally waits for animations to complete.
  # @see Calabash::Cucumber::WaitHelpers#wait_for_element_exists
  # @see #trait
  # @param {Hash} wait_opts options hash to pass to `wait_for_element_exists`
  #   (see {Calabash::Cucumber::WaitHelpers#wait_for} and {Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS}).
  # @return {IBase} self
  def await(wait_opts={})
    wait_for_elements_exist([trait], wait_opts)
    unless wait_opts.has_key?(:await_animation) && !wait_opts[:await_animation]
      sleep(transition_duration)
    end
    self
  end

  ##
  # Performs a transition from receiver page to another by performing a +:tap+ gesture
  # or a user specified +:action+.
  # Caller must supply a hash of options +transition_options+ to describe the transition.
  # Transition options may have the following keys
  #
  # +:tap+: A uiquery used to perform a tap gesture to begin transition
  # +:action+: A proc to use begin transition (either :tap or :action must be supplied)
  # +:page+: A page object or page object class to transition to (target page). If a class is provided this
  # is instantiated using the +page+ method of self. If no +:page+ is supplied, +self+ is used.
  # +:await+: If specified and truthy will await the +:page+ after performing gesture (usually to wait
  # for animation to finish)
  # +:tap_options+: If +:tap+ is provided used to pass as options to touch
  # +:wait_options+: When awaiting target page, pass these options to the +await+ method
  #
  # Returns the transition target page
  #
  # Note it is assumed that the target page is a Calabash::IBase (or acts accordingly)
  def transition(transition_options={})
    uiquery = transition_options[:tap]
    action = transition_options[:action]
    page_arg = transition_options[:page]
    should_await = transition_options.has_key?(:await) ? transition_options[:await] : true

    if action.nil? && uiquery.nil?
      raise "Called transition without providing a gesture (:tap or :action) #{transition_options}"
    end

    if uiquery
      tap_options = transition_options[:tap_options] || {}
      touch(uiquery, tap_options)
    else
      action.call()
    end

    page_obj = page_arg.is_a?(Class) ? page(page_arg) : page_arg
    page_obj ||= self

    if should_await
      wait_opts = transition_options[:wait_options] || {}
      if page_obj == self
        unless wait_opts.has_key?(:await_animation) && !wait_opts[:await_animation]
          sleep(transition_duration)
        end
      else
        page_obj.await(wait_opts)
      end
    end

    page_obj
  end

  # @!visibility private
  def await_screenshot(wait_opts={}, screenshot_opts={})
    await(wait_opts)
    screenshot_embed(screenshot_opts)
  end


  protected
  def method_missing(name, *args, &block)
    world.send(name, *args, &block)
  end

end