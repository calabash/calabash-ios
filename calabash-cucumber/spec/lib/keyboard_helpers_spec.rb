
describe Calabash::Cucumber::KeyboardHelpers do

  let(:world) do
    Class.new do
      include Calabash::Cucumber::KeyboardHelpers

      require "calabash-cucumber/status_bar_helpers"
      include Calabash::Cucumber::StatusBarHelpers

      require "calabash-cucumber/environment_helpers"
      include Calabash::Cucumber::EnvironmentHelpers

      # Also includes FailureHelpers, TestHelpers, and Core
      require "calabash-cucumber/wait_helpers"
      include Calabash::Cucumber::WaitHelpers

      require "calabash-cucumber/uia"
      include Calabash::Cucumber::UIA

      # The dread Cucumber embed
      def embed(_, _, _); ; end
    end.new
  end

  context "#docked_keyboard_visibile" do
    it "returns false if keyboard query returns nil" do
      expect(world).to receive(:_query_for_keyboard).and_return(nil)

      expect(world.docked_keyboard_visible?).to be_falsey
    end

    it "returns true if visible keyboard and the device family is iphone" do
      expect(world).to receive(:_query_for_keyboard).and_return(true)
      expect(world).to receive(:device_family_iphone?).and_return(true)

      expect(world.docked_keyboard_visible?).to be_truthy
    end

    context "iPad" do
      before do
        expect(world).to receive(:device_family_iphone?).and_return(false)
      end

      context "landscape orientation" do

        before do
          expect(world).to receive(:landscape?).and_return(true)
        end

        it "returns true if the keyboard is anchored to the bottom" do
          dimensions = {:width => 1000, :scale => 2 }
          expect(world).to receive(:screen_dimensions).and_return(dimensions)

          keyboard = { "rect" => { "height" => 100, "y" => 400 } }
          expect(world).to receive(:_query_for_keyboard).and_return(keyboard)

          expect(world.docked_keyboard_visible?).to be_truthy
        end

        it "returns false if the keyboard is not anchored to the bottom" do
          dimensions = {:width => 1000, :scale => 2 }
          expect(world).to receive(:screen_dimensions).and_return(dimensions)

          keyboard = { "rect" => { "height" => 100, "y" => 500 } }
          expect(world).to receive(:_query_for_keyboard).and_return(keyboard)

          expect(world.docked_keyboard_visible?).to be_falsey
        end
      end

      context "portrait orientation" do
        before do
          expect(world).to receive(:landscape?).and_return(false)
        end

        it "returns true if the keyboard is anchored to the bottom" do
          dimensions = {:height => 1000, :scale => 2 }
          expect(world).to receive(:screen_dimensions).and_return(dimensions)

          keyboard = { "rect" => { "height" => 100, "y" => 400 } }
          expect(world).to receive(:_query_for_keyboard).and_return(keyboard)

          expect(world.docked_keyboard_visible?).to be_truthy
        end

        it "returns false if the keyboard is not anchored to the bottom" do
          dimensions = {:height => 1000, :scale => 2 }
          expect(world).to receive(:screen_dimensions).and_return(dimensions)

          keyboard = { "rect" => { "height" => 100, "y" => 500 } }
          expect(world).to receive(:_query_for_keyboard).and_return(keyboard)

          expect(world.docked_keyboard_visible?).to be_falsey
        end
      end
    end
  end

  context "#undocked_keyboard_visible?" do
    it "returns false if the device is not an iPad" do
      expect(world).to receive(:device_family_iphone?).and_return(true)

      expect(world.undocked_keyboard_visible?).to be_falsey
    end

    context "iPad" do
      before do
        expect(world).to receive(:device_family_iphone?).and_return(false)
      end

      it "returns false if no keyboard is visible with query" do
        expect(world).to receive(:_query_for_keyboard).and_return(nil)

        expect(world.undocked_keyboard_visible?).to be_falsey
      end

      it "returns false if the visible keyboard is a docked keyboard" do
        expect(world).to receive(:_query_for_keyboard).and_return("keyboard element")
        expect(world).to receive(:docked_keyboard_visible?).and_return(true)

        expect(world.undocked_keyboard_visible?).to be_falsey
      end

      it "returns true the visible keyboard is not docked" do
        expect(world).to receive(:_query_for_keyboard).and_return("keyboard element")
        expect(world).to receive(:docked_keyboard_visible?).and_return(false)

        expect(world.undocked_keyboard_visible?).to be_truthy
      end
    end
  end

  context "#split_keyboard_visible" do
    it "returns false if the device is not an iPad" do
      expect(world).to receive(:device_family_iphone?).and_return(true)

      expect(world.split_keyboard_visible?).to be_falsey
    end

    context "iPad" do
      before do
        expect(world).to receive(:device_family_iphone?).and_return(false)
      end

      it "returns false if the split keyboard query returns no elements" do
        expect(world).to receive(:_query_for_split_keyboard).and_return(nil)

        expect(world.split_keyboard_visible?).to be_falsey
      end

      it "returns false if the split keyboard query returns true, but there is visible keyboard" do
        expect(world).to receive(:_query_for_split_keyboard).and_return("keyboard element")
        expect(world).to receive(:_query_for_keyboard).and_return("keyboard element")

        expect(world.split_keyboard_visible?).to be_falsey
      end

      it "returns true if the split keyboard query returns true and there is not a visible keyboard" do
        expect(world).to receive(:_query_for_split_keyboard).and_return("keyboard element")
        expect(world).to receive(:_query_for_keyboard).and_return(nil)

        expect(world.split_keyboard_visible?).to be_truthy
      end
    end
  end

  context "#keyboard_visible" do
    it "returns false if there is no keyboard visible" do
      expect(world).to receive(:docked_keyboard_visible?).and_return(false)
      expect(world).to receive(:undocked_keyboard_visible?).and_return(false)
      expect(world).to receive(:split_keyboard_visible?).and_return(false)

      expect(world.keyboard_visible?).to be_falsey
    end

    it "returns true if there is a docked keyboard" do
      expect(world).to receive(:docked_keyboard_visible?).and_return(true)

      expect(world.keyboard_visible?).to be_truthy
    end

    it "returns true if there is a undocked keyboard" do
      expect(world).to receive(:docked_keyboard_visible?).and_return(false)
      expect(world).to receive(:undocked_keyboard_visible?).and_return(true)

      expect(world.keyboard_visible?).to be_truthy
    end

    it "returns true if there is a split keyboard" do
      expect(world).to receive(:docked_keyboard_visible?).and_return(false)
      expect(world).to receive(:undocked_keyboard_visible?).and_return(false)
      expect(world).to receive(:split_keyboard_visible?).and_return(true)

      expect(world.keyboard_visible?).to be_truthy
    end
  end

  context "#expect_keyboard_visible!" do
    it "returns true if there is a visible keyboard" do
      expect(world).to receive(:keyboard_visible?).and_return(true)

      expect(world.expect_keyboard_visible!).to be_truthy
    end

    it "raises an error if keyboard is not visible" do
      expect(world).to receive(:keyboard_visible?).and_return(false)
      expect(world).to receive(:screenshot_and_raise).and_raise(
        "Keyboard is not visible"
      )

      expect do
        world.expect_keyboard_visible!
      end.to raise_error RuntimeError, /Keyboard is not visible/
    end
  end

  context "#wait_for_keyboard" do
    it "waits for keyboard to appear" do
      expect(world).to receive(:keyboard_visible?).and_return(false, false, true)

      options = { :retry_frequency => 0, :post_timeout => 0.0}
      expect(world.wait_for_keyboard(options)).to be_truthy
    end

    it "raises an error if keyboard does not appear" do
      expect(world).to receive(:keyboard_visible?).at_least(:once).and_return(false)
      expect(world).to receive(:screenshot).and_return(true)
      expect(world).to receive(:embed).and_return(true)

      options = { :retry_frequency => 0, :timeout => 0.05 }
      expect do
        world.wait_for_keyboard(options)
      end.to raise_error Calabash::Cucumber::WaitHelpers::WaitError,
                         /Keyboard did not appear/
    end

    it "merges the options it passes to wait_for" do
      options = { :post_timeout => 100.0, :timeout_message => "Alternative message" }
      expect(world).to receive(:wait_for).with(options).and_return(true)

      expect(world.wait_for_keyboard(options)).to be_truthy
    end
  end

  context "#wait_for_no_keyboard" do
    it "waits for keyboard to disappear" do
      expect(world).to receive(:keyboard_visible?).and_return(true, true, false)

      options = { :retry_frequency => 0, :post_timeout => 0.0}
      expect(world.wait_for_no_keyboard(options)).to be_truthy
    end

    it "raises an error if keyboard does not appear" do
      expect(world).to receive(:keyboard_visible?).at_least(:once).and_return(true)
      expect(world).to receive(:screenshot).and_return(true)
      expect(world).to receive(:embed).and_return(true)

      options = { :retry_frequency => 0, :timeout => 0.05 }
      expect do
        world.wait_for_no_keyboard(options)
      end.to raise_error Calabash::Cucumber::WaitHelpers::WaitError,
                         /Keyboard is visible/
    end

    it "merges the options it passes to wait_for" do
      options = { :timeout_message => "Alternative message" }
      expect(world).to receive(:wait_for).with(options).and_return(true)

      expect(world.wait_for_no_keyboard(options)).to be_truthy
    end
  end

  context "#uia_keyboard_visible?" do
    it "raises an error if not called in the context of UIAutomation" do
      expect(world).to receive(:uia_available?).and_return(false)

      expect do
        world.uia_keyboard_visible?
      end.to raise_error RuntimeError, /This method requires UIAutomation/
    end

    context "UIA" do

      before do
        expect(world).to receive(:uia_available?).and_return(true)
      end

      it "returns true if UIA window query is != ':nil'" do
        expect(world).to receive(:uia_query_windows).with(:keyboard).and_return("anything by :nil")

        expect(world.uia_keyboard_visible?).to be_truthy
      end

      it "returns false if UIA window query is == ':nil'" do
        expect(world).to receive(:uia_query_windows).with(:keyboard).and_return(":nil")

        expect(world.uia_keyboard_visible?).to be_falsey
      end
    end
  end

  context "#uia_wait_for_keyboard" do
    it "raises an error if not called in the context of UIAutomation" do

    end

    context "UIA" do

      before do
        expect(world).to receive(:uia_available?).and_return(true)
      end

      it "waits for keyboard to appear" do
        expect(world).to receive(:uia_keyboard_visible?).and_return(false, false, true)

        options = { :retry_frequency => 0, :post_timeout => 0.0}
        expect(world.uia_wait_for_keyboard(options)).to be_truthy
      end

      it "raises an error if keyboard does not appear" do
        expect(world).to receive(:uia_keyboard_visible?).at_least(:once).and_return(false)
        expect(world).to receive(:screenshot).and_return(true)
        expect(world).to receive(:embed).and_return(true)

        options = { :retry_frequency => 0, :timeout => 0.05 }
        expect do
          world.uia_wait_for_keyboard(options)
        end.to raise_error Calabash::Cucumber::WaitHelpers::WaitError,
                           /Keyboard did not appear/
      end

      it "merges the options it passes to wait_for" do
        options = {
          :post_timeout => 100,
          :timeout_message => "Alternative message",
          :retry_frequency => 0.1,
          :timeout => 100
        }
        expect(world).to receive(:wait_for).with(options).and_return(true)

        expect(world.uia_wait_for_keyboard(options)).to be_truthy
      end
    end
  end

  context "#text_from_first_responder" do
    it "responds to _text_from_first_responder" do
      expect(world.respond_to?(:_text_from_first_responder)).to be_truthy
    end

    it "raises an error when called when there is no visible keyboard" do
      expect(world).to receive(:keyboard_visible?).and_return(false)
      expect(world).to receive(:screenshot_and_raise).and_raise(
        "There must be a visible keyboard"
      )

      expect do
        world.text_from_first_responder
        end.to raise_error RuntimeError, /There must be a visible keyboard/
    end

    context "visible keyboard" do

      before do
        expect(world).to receive(:keyboard_visible?).and_return(true)
      end

      it "returns the text of a text field when it is the first responder" do
        query = "textField isFirstResponder:1"
        expect(world).to(
          receive(:_query_wrapper).with(query, :text)
        ).and_return(["text field text"])

        actual = world.text_from_first_responder
        expect(actual).to be == "text field text"
      end

      it "returns the test of text view when it is the first responder" do
        query = "textField isFirstResponder:1"
        expect(world).to(
          receive(:_query_wrapper).with(query, :text)
        ).and_return([])

        query = "textView isFirstResponder:1"
        expect(world).to(
          receive(:_query_wrapper).with(query, :text)
        ).and_return(["text view text"])

        actual = world.text_from_first_responder
        expect(actual).to be == "text view text"
      end

      it "returns an empty string when no first responder can be found" do
        query = "textField isFirstResponder:1"
        expect(world).to(
          receive(:_query_wrapper).with(query, :text)
        ).and_return([])

        query = "textView isFirstResponder:1"
        expect(world).to(
          receive(:_query_wrapper).with(query, :text)
        ).and_return([])

        actual = world.text_from_first_responder
        expect(actual).to be == ""
      end
    end
  end

  context "#_query_wrapper" do
    it "calls Map.map" do
      expect(Calabash::Cucumber::Map).to(
      receive(:map).with("query", :query, "a", "b", "c")
      ).and_return(["d", "e", "f"])

      actual = world.send(:_query_wrapper, "query", "a", "b", "c")
      expect(actual).to be == ["d", "e", "f"]
    end
  end

  context "#_query_for_keyboard" do
    before do
      stub_const("Calabash::Cucumber::KeyboardHelpers::KEYBOARD_QUERY", "query")
    end

    it "returns the keyboard element if it is visible to query" do
      result = ["keyboard element", "other element"]
      expect(world).to receive(:_query_wrapper).with("query").and_return(result)

      expect(world.send(:_query_for_keyboard)).to be == "keyboard element"
    end

    it "returns nil if the keyboard is not visible query" do
      result = []
      expect(world).to receive(:_query_wrapper).with("query").and_return(result)

      expect(world.send(:_query_for_keyboard)).to be == nil
    end
  end

  context "#_query_for_split_keyboard" do
    before do
      stub_const("Calabash::Cucumber::KeyboardHelpers::SPLIT_KEYBOARD_QUERY", "query")
    end

    it "returns the split keyboard element if it is visible to query" do
      result = ["keyboard element", "other element"]
      expect(world).to receive(:_query_wrapper).with("query").and_return(result)

      expect(world.send(:_query_for_split_keyboard)).to be == "keyboard element"
    end

    it "returns nil if the split keyboard is not visible query" do
      result = []
      expect(world).to receive(:_query_wrapper).with("query").and_return(result)

      expect(world.send(:_query_for_split_keyboard)).to be == nil
    end
  end
end
