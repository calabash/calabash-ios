
describe Calabash::Cucumber::Gestures::DeviceAgent do

  let(:xcuitest) do
    Class.new(RunLoop::XCUITest) do
      def initialize; ; end
      def to_s; "#<XCUITest subclass>"; end
      def inspect; to_s; end
    end.new
  end

  it ".name" do
    expect(Calabash::Cucumber::Gestures::DeviceAgent.name).to be == :device_agent
  end

  context ".expect_valid_args" do
    it "raises error if args is nil" do
      expect do
        Calabash::Cucumber::Gestures::DeviceAgent.expect_valid_args(nil)
      end.to raise_error ArgumentError, /Expected args to be a non-nil Array/
    end

    it "raises error if args is not an Array" do
      expect do
        Calabash::Cucumber::Gestures::DeviceAgent.expect_valid_args({})
      end.to raise_error ArgumentError, /Expected args to be an Array,/
    end

    it "raises error if args.count != 1" do
      expect do
        Calabash::Cucumber::Gestures::DeviceAgent.expect_valid_args(["a", "b", "c"])
      end.to raise_error ArgumentError, /Expected args to be an Array with one element/
    end

    it "raises error if arg[0] is not a RunLoop::XCUITest instance" do
      expect do
        Calabash::Cucumber::Gestures::DeviceAgent.expect_valid_args(["a"])
      end.to raise_error ArgumentError,
                         /Expected first element of args to be a RunLoop::XCUITest instance/
    end

    it "returns true if args are valid" do
      args = [xcuitest]
      actual = Calabash::Cucumber::Gestures::DeviceAgent.expect_valid_args(args)
      expect(actual).to be_truthy
    end
  end

  it ".new" do
    device_agent = Calabash::Cucumber::Gestures::DeviceAgent.new(xcuitest)

    expect(device_agent).to be_truthy
    expect(device_agent.device_agent).to be == xcuitest
    expect(device_agent.instance_variable_get(:@device_agent)).to be == xcuitest
  end

  context "instance methods" do
    let(:device_agent) do
      Calabash::Cucumber::Gestures::DeviceAgent.new(xcuitest)
    end

    let(:query) { "query" }
    let(:options) { {:query => query} }

    context "#query_for_coordinates" do
      it "raises an error if query returns no elements" do
        expect(device_agent).to receive(:first_element_for_query).with(query).and_return(nil)
        allow_any_instance_of(Calabash::Cucumber::Map).to receive(:screenshot_and_raise).and_raise(RuntimeError, "Screenshot")

        expect do
          device_agent.send(:query_for_coordinates, options)
        end.to raise_error RuntimeError, /Screenshot/
      end

      it "returns a hash with :coordinates and :view" do
        expect(device_agent).to receive(:first_element_for_query).with(query).and_return("a")
        expect(device_agent).to receive(:point_from).with("a").and_return(:coordinates)

        actual = device_agent.send(:query_for_coordinates, options)
        expect(actual[:coordinates]).to be == :coordinates
        expect(actual[:view]).to be == "a"
      end
    end

    context "#first_element_for_query" do
      let(:results) { [] }
      let(:response) { {"results" => results } }

      it "returns nil if query returns no results" do
        expect(Calabash::Cucumber::Map).to receive(:raw_map).and_return(response)

        expect(device_agent.send(:first_element_for_query, "query")).to be == nil
      end

      it "returns the first element of query result" do
        results << "a"
        expect(Calabash::Cucumber::Map).to receive(:raw_map).and_return(response)

        expect(device_agent.send(:first_element_for_query, "query")).to be == "a"
      end
    end
  end
end
