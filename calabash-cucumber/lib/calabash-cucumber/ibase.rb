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

end