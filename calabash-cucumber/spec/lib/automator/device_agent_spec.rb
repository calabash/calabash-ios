
describe Calabash::Cucumber::Automator::DeviceAgent do

  let(:client) do
    Class.new(RunLoop::DeviceAgent::Client) do
      def initialize; ; end
      def to_s; "#<DeviceAgent::Client RSPEC>"; end
      def inspect; to_s; end
      def rotate_home_button_to(_); ; end
      def perform_coordinate_gesture(_, _, _, _={}); ; end
      def pan_between_coordinates(_, _, _={}); ; end
    end.new
  end

  context ".expect_valid_args" do
    it "raises error if args is nil" do
      expect do
        Calabash::Cucumber::Automator::DeviceAgent.expect_valid_args(nil)
      end.to raise_error ArgumentError, /Expected args to be a non-nil Array/
    end

    it "raises error if args is not an Array" do
      expect do
        Calabash::Cucumber::Automator::DeviceAgent.expect_valid_args({})
      end.to raise_error ArgumentError, /Expected args to be an Array,/
    end

    it "raises error if args.count != 1" do
      expect do
        Calabash::Cucumber::Automator::DeviceAgent.expect_valid_args(["a", "b", "c"])
      end.to raise_error ArgumentError, /Expected args to be an Array with one element/
    end

    it "raises error if arg[0] is not a RunLoop::DeviceAgent::Client instance" do
      expect do
        Calabash::Cucumber::Automator::DeviceAgent.expect_valid_args(["a"])
      end.to raise_error ArgumentError,
                         /Expected first element of args to be a RunLoop::DeviceAgent::Client instance/
    end

    it "returns true if args are valid" do
      args = [client]
      actual = Calabash::Cucumber::Automator::DeviceAgent.expect_valid_args(args)
      expect(actual).to be_truthy
    end
  end

  it ".new" do
    device_agent = Calabash::Cucumber::Automator::DeviceAgent.new(client)

    expect(device_agent).to be_truthy
    expect(device_agent.client).to be == client
    expect(device_agent.instance_variable_get(:@client)).to be == client
  end

  context "instance methods" do
    let(:device_agent) do
      Calabash::Cucumber::Automator::DeviceAgent.new(client)
    end

    let(:query) { "query" }
    let(:options) { {:query => query} }

    context "#name" do
      it "returns :device_agent" do
        expect(device_agent.name).to be == :device_agent
      end
    end

    context "#rotate" do
      it "rotates the interface based on direction" do
        expect(device_agent).to receive(:status_bar_orientation).and_return("orientation")
        expect(device_agent).to receive(:orientation_key).with(:left, :orientation).and_return(:key)
        expect(device_agent).to receive(:orientation_for_key).with(:key).and_return(:value)
        expect(device_agent).to receive(:rotate_home_button_to).with(:value).and_return(:new_orientation)

        expect(device_agent.rotate(:left)).to be == :new_orientation
      end
    end

    context "#rotate_home_button_to" do
      it "rotates and returns the current status bar orientation" do
        expect(client).to receive(:rotate_home_button_to).with(:position).and_return true
        expect(device_agent).to receive(:status_bar_orientation).and_return("new_orientation")

        expect(device_agent.rotate_home_button_to(:position)).to be == :new_orientation
      end
    end

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
        expect(device_agent).to receive(:point_from).with("a", options).and_return(:coordinates)

        actual = device_agent.send(:query_for_coordinates, options)
        expect(actual[:coordinates]).to be == :coordinates
        expect(actual[:view]).to be == "a"
      end

      context ":query is nil" do
        it "raises an ArgumentError if there is not an :offset" do
          expect do
            device_agent.send(:query_for_coordinates, {})
          end.to raise_error ArgumentError,
                             /If query is nil, there must be a valid offset/
        end

        it "raises an ArgumentError if there is not a valid :offset" do
          expect do
            device_agent.send(:query_for_coordinates, {offset: { x: 10 }})
          end.to raise_error ArgumentError,
                             /If query is nil, there must be a valid offset/

          expect do
            device_agent.send(:query_for_coordinates, {offset: { y: 10 }})
          end.to raise_error ArgumentError,
                             /If query is nil, there must be a valid offset/
        end

        it "returns a hash with the :coordinate and :view values the same" do
          options = {offset: {x: 10, y: 20}}

          actual = device_agent.send(:query_for_coordinates, options)
          expect(actual[:coordinates]).to be == options[:offset]
          expect(actual[:view]).to be == options[:offset]
        end
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

      it "raises an ArgumentError if uiquery is nil" do
        expect do
          device_agent.send(:first_element_for_query, nil)
        end.to raise_error ArgumentError, /Query cannot be nil/
      end
    end

    context "#element_for_device_screen" do
      it "returns a Hash representation of device_screen" do
        device = Resources.shared.device_for_mocking
        expect(device_agent).to receive(:device).and_return(device)
        expected = {
          "screen" => true,
          "rect" => {
            "height" => 568,
            "width" => 320,
            "center_x" => 160,
            "center_y" => 284
          }
        }

        actual = device_agent.send(:element_for_device_screen)
        expect(actual).to be == expected
      end
    end

    context "#touch" do
      it "performs a touch and returns an array with one element" do
        hash = {
          :view => "the view acted on",
          :coordinates => {
            :x => 10,
            :y => 20
          }
        }

        options = {}

        expect(device_agent).to receive(:query_for_coordinates).with(options).and_return(hash)
        expect(device_agent.client).to(
          receive(:perform_coordinate_gesture).with("touch", 10, 20)).and_return(true)
        expected = [hash[:view]]

        expect(device_agent.touch(options)).to be == expected
      end
    end

    context "#double_tap" do
      it "performs a double tap and returns an array with one element" do
        hash = {
          :view => "the view acted on",
          :coordinates => {
            :x => 10,
            :y => 20
          }
        }

        options = {}

        expect(device_agent).to receive(:query_for_coordinates).with(options).and_return(hash)
        expect(device_agent.client).to(
          receive(:perform_coordinate_gesture).with("double_tap", 10, 20)).and_return(true)
        expected = [hash[:view]]

        expect(device_agent.double_tap(options)).to be == expected
      end
    end

    context "#two_finger_tap" do
      it "performs a two-finger tap and returns an array with one element" do
        hash = {
          :view => "the view acted on",
          :coordinates => {
            :x => 10,
            :y => 20
          }
        }

        options = {}

        expect(device_agent).to receive(:query_for_coordinates).with(options).and_return(hash)
        expect(device_agent.client).to(
          receive(:perform_coordinate_gesture).with("two_finger_tap", 10, 20)).and_return(true)
        expected = [hash[:view]]

        expect(device_agent.two_finger_tap(options)).to be == expected
      end
    end

    context "#touch_hold" do
      let(:hash) do
        {
          :view => "the view acted on",
          :coordinates => {
            :x => 10,
            :y => 20
          },
        }
      end

      let(:options) { {} }

      it "performs a long press for 3 seconds and returns an array with one element" do
        expect(device_agent).to receive(:query_for_coordinates).with(options).and_return(hash)
        expect(device_agent.client).to(
          receive(:perform_coordinate_gesture).with("touch",
                                                    10, 20,
                                                    {:duration => 3 })).and_return(true)
        expected = [hash[:view]]

        expect(device_agent.touch_hold(options)).to be == expected
      end

      it "performs a long press for N seconds and returns an array with one element" do
        options[:duration] = 1

        expect(device_agent).to receive(:query_for_coordinates).with(options).and_return(hash)
        expect(device_agent.client).to(
          receive(:perform_coordinate_gesture).with("touch",
                                                    10, 20,
                                                    {:duration => 1 })).and_return(true)
        expected = [hash[:view]]

        expect(device_agent.touch_hold(options)).to be == expected
      end
    end

    context "#pan" do
      it "pans between the center of the queries and returns both views" do
        from_query = "from"
        to_query = "to"
        options = {:duration => 1.0}

        from_options = options.merge({:query => from_query})
        to_options = options.merge({:query => to_query})

        from_hash = {:coordinates => :from_point,
                     :view => :from_view}

        to_hash = {:coordinates => :to_point,
                     :view => :to_view}


        expect(device_agent).to(
          receive(:query_for_coordinates).with(from_options).and_return(from_hash)
        )

        expect(device_agent).to(
          receive(:query_for_coordinates).with(to_options).and_return(to_hash)
        )

        expect(device_agent.client).to(
          receive(:pan_between_coordinates).with(:from_point, :to_point,
                                                 {:duration => 1.0}).and_return(true)
        )

        actual = device_agent.pan(from_query, to_query, options)
        expect(actual[0]).to be == :from_view
        expect(actual[1]).to be == :to_view
        expect(actual.count).to be == 2
      end
    end

    context "#pan_coordinates" do
      it "pans between two coordinates" do
        options = {:duration => 1.0}

        expect(client).to(
          receive(:pan_between_coordinates).with(:from_point, :to_point,
                                                 {:duration => 1.0}).and_return(true)
        )

        expect(device_agent).to(
          receive(:first_element_for_query).with("*").and_return(:view)
        )

        actual = device_agent.pan_coordinates(:from_point, :to_point, options)
        expect(actual).to be == [:view]
      end
    end

    context "#swipe" do
      let(:force) { :strong }
      let(:direction) { :left }
      let(:gesture_options) { { duration: 0.2 } }

      context "nil query" do
        let(:options) { { force: force, direction: direction, query: nil } }

        it "performs the gesture using screen coordinates" do
          element = {
            "screen" => true,
            "rect" => {
              "height" => 200,
              "width" => 100,
              "center_x" => 50,
              "center_y" => 100
            }
          }

          from_point = {x: 50, y: 100}
          to_point = {x: 75, y: 125 }

          expect(device_agent).to receive(:element_for_device_screen).and_return(element)
          expect(device_agent).to receive(:point_from).and_return(from_point)
          expect(Calabash::Cucumber::Automator::Coordinates).to(
            receive(:end_point_for_swipe).with(:left, element, :strong).and_return(to_point)
          )

          expect(device_agent.client).to(
            receive(:pan_between_coordinates).with(from_point, to_point, gesture_options)
          ).and_return(true)

          expect(device_agent.swipe(options)).to be == [element]
        end
      end

      context "non-nil query" do
        let(:options) { { force: force, direction: direction, query: "query" } }

        it "performs the gesture using query coordinates" do
          element = {:view => true}
          hash = {
            :coordinates => {x: 50, y: 100},
            :view => element
          }

          to_point = {x: 75, y: 125 }
          from_point = hash[:coordinates]

          expect(device_agent).to receive(:query_for_coordinates).and_return(hash)
          expect(Calabash::Cucumber::Automator::Coordinates).to(
            receive(:end_point_for_swipe).with(:left, element, :strong).and_return(to_point)
          )

          expect(device_agent.client).to(
            receive(:pan_between_coordinates).with(from_point, to_point, gesture_options)
          ).and_return(true)

          expect(device_agent.swipe(options)).to be == [element]
        end
      end
    end

    context "#flick" do
      let(:gesture_options) { {:duration => 0.2} }
      let(:delta) { {x: -88.0, y: 88.0} }
      let(:scaled_delta) { {x: delta[:x] * 2.0, y: delta[:y] * 2.0} }
      let(:offset) { {:offset => scaled_delta} }
      let(:options) { {:delta => delta, :query => "query" } }

      it "calls #pan_between_coordinates" do
        expect(device_agent).to(
          receive(:query_for_coordinates).with(options).and_return({:coordinates => :point,
                                                                    :view => :view})
        )

        expect(device_agent).to receive(:point_from).with(:view).and_return(:start)
        expect(device_agent).to receive(:point_from).with(:view, offset).and_return(:end)

        expect(device_agent.client).to(
          receive(:pan_between_coordinates).with(:start, :end, gesture_options).and_return(true)
        )

        actual = device_agent.flick(options)
        expect(actual).to be == [:view]
      end
    end

    context "Text Entry" do
      context "#enter_text_with_keyboard" do
        it "types a string by calling out to enter_text" do
          expect(device_agent.client).to receive(:enter_text).with("text").and_return({})

          expect(device_agent.enter_text_with_keyboard("text")).to be == {}
        end
      end

      context "#enter_char_with_keyboard" do
        it "types a char by calling out to enter_text" do
          expect(device_agent.client).to receive(:enter_text).with("c").and_return({})

          expect(device_agent.enter_text_with_keyboard("c")).to be == {}
        end
      end

      context "#char_for_keyboard_action" do
        let(:hash) { { "action" => "char"  } }

        before do
          stub_const("Calabash::Cucumber::Automator::DeviceAgent::SPECIAL_ACTION_CHARS", hash)
        end

        it "returns the value of the action key" do
          expect(device_agent.char_for_keyboard_action("action")).to be == "char"
        end

        it "returns nil if there is no char for the action" do
          expect(device_agent.char_for_keyboard_action("unknown")).to be == nil
        end
      end

      context "#tap_keyboard_action_key" do
        it "touches the action key using device_agent #touch if mark can be found" do
          expect(device_agent).to(
            receive(:mark_for_return_key_of_first_responder)
          ).and_return("Mark")
          expect(device_agent.client).to receive(:touch).with({marked: "Mark"}).and_return({})

          expect(device_agent.tap_keyboard_action_key).to be == {}
        end

        it "touches the action key by typing a newline if the type is unknown" do
          expect(device_agent).to(
            receive(:mark_for_return_key_of_first_responder)
          ).and_return(nil)
          expect(device_agent).to receive(:char_for_keyboard_action).and_return("\n")
          expect(device_agent.client).to receive(:enter_text).with("\n").and_return({})

          expect(device_agent.tap_keyboard_action_key).to be == {}
        end

        it "touches the action key by typing a newline if DeviceAgent can't find a match" do
          expect(device_agent).to(
            receive(:mark_for_return_key_of_first_responder)
          ).and_return("Unmatchable identifier")

          expect(device_agent.client).to(
            receive(:touch).with({marked: "Unmatchable identifier"}).and_raise(
              RuntimeError, "No match found")
          )

          expect(device_agent).to receive(:char_for_keyboard_action).and_return("\n")
          expect(device_agent.client).to receive(:enter_text).with("\n").and_return({})

          expect(device_agent.tap_keyboard_action_key).to be == {}
        end
      end

      context "#tap_keyboard_delete_key" do
        it "touches the keyboard delete key" do
          expect(device_agent.client).to receive(:touch).with({marked: 'delete'}).and_return({})

          expect(device_agent.tap_keyboard_delete_key).to be == {}
        end
      end

      context "#fast_enter_text" do
        it "calls 'enter_text'" do
          expect(device_agent.client).to receive(:enter_text).with("text").and_return({})

          expect(device_agent.fast_enter_text("text")).to be == {}
        end
      end

      context "#dismiss_ipad_keyboard" do
        it "touches the hide keyboard key" do
          expect(device_agent.client).to receive(:touch).with({marked: "Hide keyboard"}).and_return({})

          expect(device_agent.dismiss_ipad_keyboard).to be == {}
        end
      end

      context "#mark_for_return_key_type" do
        let(:hash) { { 1 => "A", 3 => "Join" } }

        before do
          stub_const("Calabash::Cucumber::Automator::DeviceAgent::RETURN_KEY_TYPE", hash)
        end

        it "returns the string value for the text input view returnKeyType" do
          expect(device_agent.send(:mark_for_return_key_type, 1)).to be == "A"
        end

        it "returns nil if there is no value the text input view returnKeyType" do
          expect(device_agent.send(:mark_for_return_key_type, 2)).to be == nil
        end

        context "handling Join" do
          it "returns Join for simulators" do
            expect(device_agent).to receive(:simulator?).and_return(true)

            expect(device_agent.send(:mark_for_return_key_type, 3)).to be == "Join"
          end

          it "returns Join: for physical devices" do
            expect(device_agent).to receive(:simulator?).and_return(false)

            expect(device_agent.send(:mark_for_return_key_type, 3)).to be == "Join:"
          end
        end
      end

      context "#return_key_type_of_first_responder" do
        it "returns the returnKeyType of text field when it is the first responder" do
          query = "textField isFirstResponder:1"
          expect(Calabash::Cucumber::Map).to(
            receive(:raw_map).with(query, :query, :returnKeyType)
          ).and_return({"results" => [1]})

          actual = device_agent.send(:return_key_type_of_first_responder)
          expect(actual).to be == 1
        end

        it "returns the returnKeyType of text view when it is the first responder" do
          query = "textField isFirstResponder:1"
          expect(Calabash::Cucumber::Map).to(
            receive(:raw_map).with(query, :query, :returnKeyType)
          ).and_return({"results" => []})

          query = "textView isFirstResponder:1"
          expect(Calabash::Cucumber::Map).to(
            receive(:raw_map).with(query, :query, :returnKeyType)
          ).and_return({"results" => [2]})

          actual = device_agent.send(:return_key_type_of_first_responder)
          expect(actual).to be == 2
        end

        it "returns nil when no first responder can be found" do
          query = "textField isFirstResponder:1"
          expect(Calabash::Cucumber::Map).to(
            receive(:raw_map).with(query, :query, :returnKeyType)
          ).and_return({"results" => []})

          query = "textView isFirstResponder:1"
          expect(Calabash::Cucumber::Map).to(
            receive(:raw_map).with(query, :query, :returnKeyType)
          ).and_return({"results" => []})

          actual = device_agent.send(:return_key_type_of_first_responder)
          expect(actual).to be == nil
        end
      end

      context "#mark_for_return_key_of_first_responder" do
        it "returns the returnKeyType of the first responder" do
          expect(device_agent).to receive(:return_key_type_of_first_responder).and_return(1)
          expect(device_agent).to receive(:mark_for_return_key_type).with(1).and_return("Hello")

          actual = device_agent.send(:mark_for_return_key_of_first_responder)
          expect(actual).to be == "Hello"
        end
      end
    end
  end
end

