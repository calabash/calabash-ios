require 'calabash-cucumber/core'
require 'calabash-cucumber/operations'

class Calabash::IBase
  include Calabash::Cucumber::Operations

  def initialize(world)
    @world = world
  end

  def embed(*args)
    @world.send(:embed,*args)
  end

  def puts(*args)
    @world.send(:puts, *args)
  end

  def trait
    "navigationItemView marked:'#{self.title}'"
  end

  def page(clz,*args)
    clz.new(@world,*args)
  end

  def step(s)

  end

  def steps(ss)

  end

  def await(opts={})
    wait_for_elements_exist([trait], opts)
    self
  end

  def await_screenshot(wait_opts={},screenshot_opts={})
    await(wait_opts)
    screenshot_embed(screenshot_opts)
  end

end