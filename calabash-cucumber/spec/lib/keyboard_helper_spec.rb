
describe Calabash::Cucumber::KeyboardHelpers do

  let(:world) do
    Class.new do
      include Calabash::Cucumber::KeyboardHelpers
    end.new
  end

  it "#done is deprecated" do
    expect(world).to receive(:tap_keyboard_action_key).and_return(true)

    err = capture_stderr do
      world.done
    end.string

    expect(err[/Use tap_keyboard_action_key/, 0]).to be_truthy
  end
end
