class Calabash::Base
  include Calabash::Cucumber::Operations

  def initialize(world)
    @world = world
  end

  def embed(*args)
    @world.embed(*args)
  end

  def puts
    @world.puts(*args)
  end

end