
describe Calabash::Cucumber::Map do

  let(:query) { "view marked:'my mark'" }
  let(:method_name) { :scrollToViewWithMark }
  let(:args) { ["arg0", "arg1", "arg2"] }
  let(:map) { Calabash::Cucumber::Map.new }

  it ".map_factory" do
    actual = Calabash::Cucumber::Map.send(:map_factory)
    expect(actual).to be_a_kind_of(Calabash::Cucumber::Map)
  end

  describe ".raw_map" do

    let(:failure_body) do
      JSON.generate({
        "outcome" => "FAILURE",
        "reason" => "The reason",
        "details" => "The details"
      })
    end

    let(:path) do
      dir = Resources.shared.local_tmp_dir
      File.join(dir, "screenshot.png")
    end

    before do
      allow(Calabash::Cucumber::Map).to receive(:map_factory).and_return(map)
    end

    it "calls screenshot_and_raise when not 'SUCCESS'" do
      expect(map).to receive(:http).once.and_return(failure_body)
      expect(map).to receive(:screenshot).and_return(path)

      expect do
        Calabash::Cucumber::Map.raw_map(query, method_name, args)
      end.to raise_error(RuntimeError,
                         /map view marked:'my mark', scrollToViewWithMark failed for:/)
    end
  end
end

