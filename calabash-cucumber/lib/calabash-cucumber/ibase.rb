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

  # A reference to the Cucumber World variable.
  # @!attribute [rw] world
  # @return [Object] the Cucumber World instance
  attr_accessor :world

  # The number of seconds to allow for page complete animations _after_ this
  # page trait becomes visible.
  #
  # @note By default, this value is _not_ used.  To use this additional
  #  wait time, you need to include `:await_animation => true` in the options
  #  hash that is passed the `await` and `transition` methods.
  #
  # @see #trait
  # @see #await
  # @see #transition
  #
  # @!attribute [rw] transition_duration
  # @return [Number] the number of seconds to allow for page transitions
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
  # @raise [RuntimeError] if the subclass does not respond to `title` or
  #  the subclass does not override the `trait` method
  def trait
    raise "You should define a trait method or a title method" unless respond_to?(:title)
    "navigationItemView marked:'#{self.title}'"
  end

  # Returns true if the current view shows this page's `trait`.
  # @see #trait
  # @return [Boolean] true iff `element_exists(trait)`
  def current_page?
    element_exists(trait)
  end

  # A variant of {Calabash::Cucumber::Core#page} that works inside page objects.
  #
  # @note It is assumed that `clz` will be a subclass of Calabash::IBase or will
  # behave as such.
  #
  # @see Calabash::Cucumber::Core#page
  # @see Calabash::IBase
  # @param {Class} clz the page object class to instantiate (passing the cucumber world and `args`)
  # @param {Array} args optional additional arguments to pass to the page object constructor
  # @return {Object} a fresh instance of `Class clz` which has been passed a reference to the cucumber World object.
  def page(clz, *args)
    clz.new(world, *args)
  end

  # Waits for this page's `trait` to become visible.
  #
  # After this page appears, you can optionally wait for
  # `self.transition_duration` more seconds.
  #
  # @see Calabash::Cucumber::WaitHelpers#wait_for_element_exists
  # @see Calabash::Cucumber::WaitHelpers#wait_for
  # @see #trait
  # @see #transition_duration
  #
  # @param {Hash} wait_opts options hash to pass to `wait_for_element_exists`
  #   (see {Calabash::Cucumber::WaitHelpers#wait_for} and
  #   {Calabash::Cucumber::WaitHelpers::DEFAULT_OPTS}).
  # @option wait_opts [Boolean] :await_animation (false)
  #   iff true, will wait for `self.transition_duration` after this page's
  #   `trait` appears
  # @return {IBase} self
  def await(wait_opts={})
    wait_for_elements_exist([trait], wait_opts)
    unless wait_opts.has_key?(:await_animation) && !wait_opts[:await_animation]
      sleep(transition_duration)
    end
    self
  end

  # Performs a transition from receiver page to another by performing a `tap`
  # gesture or a user specified `action`.
  #
  # Callers must supply a hash of options `transition_options` to describe the
  # transition.
  #
  # @note If a `tap` _and_ and `action` are defined, the `action` will be
  #  ignored.
  #
  # @note If `transition_options[:page]` is defined, then it is assumed its
  #   value will be a subclass of Calabash::IBase or will behave as such.
  #
  # @example Use this pattern to wait for `transition_duration` after the
  #  the target page's trait becomes visible.
  #
  #  opts = {:tap => "button marked:'login'",
  #          :wait_options => {:await_animation => true},
  #          :page => LoginPage}
  #  transition(opts)
  #
  # @param [Hash] transition_options options for controlling the transition
  #
  # @option transition_options [String] :tap
  #  A uiquery used to perform a tap gesture to begin transition.
  #
  # @option transition_options [Proc] :action
  #  A proc to use begin transition.
  #
  # @option transition_options [IBase,Class,nil] :page
  #  A page object or page object `class` to transition to (target page).
  #  If a `class` is provided it is instantiated using the `self.page` method.
  #  If no `page` is supplied, `self` is used.
  #
  # @option transition_options [Boolean] :await
  #  If true the `page`'s await will be called after performing the transition
  #  that triggers the transition.  This is useful for waiting for animations to
  #  complete.  Defaults to `true`.
  #
  # @option transition_options [Hash] :tap_options Iff a `tap` gesture is defined
  #  then these options will be passed to `touch`.
  #
  # @option transition_options [Hash] :wait_options Iff the :await key is true,
  #  then these options are passed to the `page.await` method.
  #
  # @return [IBase] the page that is transitioned to
  # @raise [RuntimeError] if `transition_options` does not include a non-nil
  #  :tap or :action key
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