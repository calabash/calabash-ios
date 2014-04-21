require 'calabash-cucumber/core'
require 'calabash-cucumber/operations'

class Calabash::IBase
  include Calabash::Cucumber::Operations

  attr_accessor :world, :transition_duration

  def initialize(world, transition_duration=0.5)
    self.world = world
    self.transition_duration = transition_duration
  end

  def trait
    raise "You should define a trait method or a title method" unless respond_to?(:title)
    "navigationItemView marked:'#{self.title}'"
  end

  def current_page?
    element_exists(trait)
  end

  def page(clz, *args)
    clz.new(world, *args)
  end

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

  def await_screenshot(wait_opts={}, screenshot_opts={})
    await(wait_opts)
    screenshot_embed(screenshot_opts)
  end


  protected
  def method_missing(name, *args, &block)
    world.send(name, *args, &block)
  end

end