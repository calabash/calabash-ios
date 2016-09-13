
describe Calabash::Cucumber::Automator::Coordinates do

  let(:window) do
    {
      "rect" => {
        "y" => 0,
        "center_x" => 187.5,
        "center_y" => 333.5,
        "x" => 0,
        "width" => 375,
        "height" => 667
      }
    }
  end

  let(:row) do
    {
      "rect" => {
        "y" => 108,
        "center_x" => 187.5,
        "center_y" => 130,
        "x" => 0,
        "width" => 375,
        "height" => 44
      }
    }
  end

  let(:coordinates) { Calabash::Cucumber::Automator::Coordinates.new(row) }

  context "class methods" do

    context "finding points" do

      before do
        expect(Calabash::Cucumber::Automator::Coordinates).to(
          receive(:instance_without_element).and_return(coordinates)
        )
      end

      it ".left_point_for_full_screen_pan" do
        expect(coordinates).to receive(:min_x).and_return(100)
        expect(coordinates).to receive(:window).and_return({:center_y => 200})

        actual = Calabash::Cucumber::Automator::Coordinates.left_point_for_full_screen_pan
        expect(actual[:x]).to be == 100
        expect(actual[:y]).to be == 200
      end

      it ".right_point_for_full_screen_pan" do
        expect(coordinates).to receive(:max_x).and_return(100)
        expect(coordinates).to receive(:window).and_return({:center_y => 200})

        actual = Calabash::Cucumber::Automator::Coordinates.right_point_for_full_screen_pan
        expect(actual[:x]).to be == 100
        expect(actual[:y]).to be == 200
      end

      it ".top_point_for_full_screen_pan" do
        expect(coordinates).to receive(:min_y).and_return(100)
        expect(coordinates).to receive(:window).and_return({:center_x => 200})

        actual = Calabash::Cucumber::Automator::Coordinates.top_point_for_full_screen_pan
        expect(actual[:x]).to be == 200
        expect(actual[:y]).to be == 100
      end

      it ".bottom_point_for_full_screen_pan" do
        expect(coordinates).to receive(:max_y).and_return(100)
        expect(coordinates).to receive(:window).and_return({:center_x => 200})

        actual = Calabash::Cucumber::Automator::Coordinates.bottom_point_for_full_screen_pan
        expect(actual[:x]).to be == 200
        expect(actual[:y]).to be == 100
      end
    end

    context ".points_for_full_screen_pan" do
      let(:klass) { Calabash::Cucumber::Automator::Coordinates }

      it "raises an exception if direction is not valid" do
        expect do
          klass.points_for_full_screen_pan(:sideways)
        end.to raise_error ArgumentError, /is not supported/
      end

      context "valid directions" do
        it ":left" do
          expect(klass).to receive(:right_point_for_full_screen_pan).and_return(:start)
          expect(klass).to receive(:left_point_for_full_screen_pan).and_return(:end)

          actual = klass.points_for_full_screen_pan(:left)
          expect(actual[:start]).to be == :start
          expect(actual[:end]).to be == :end
        end

        it ":right" do
          expect(klass).to receive(:left_point_for_full_screen_pan).and_return(:start)
          expect(klass).to receive(:right_point_for_full_screen_pan).and_return(:end)

          actual = klass.points_for_full_screen_pan(:right)
          expect(actual[:start]).to be == :start
          expect(actual[:end]).to be == :end
        end

        it ":up" do
          expect(klass).to receive(:bottom_point_for_full_screen_pan).and_return(:start)
          expect(klass).to receive(:top_point_for_full_screen_pan).and_return(:end)

          actual = klass.points_for_full_screen_pan(:up)
          expect(actual[:start]).to be == :start
          expect(actual[:end]).to be == :end
        end

        it ":down" do
          expect(klass).to receive(:top_point_for_full_screen_pan).and_return(:start)
          expect(klass).to receive(:bottom_point_for_full_screen_pan).and_return(:end)

          actual = klass.points_for_full_screen_pan(:down)
          expect(actual[:start]).to be == :start
          expect(actual[:end]).to be == :end
        end
      end
    end
  end

  context "public methods" do
    context "#left_point_for_full_view_pan" do
      it "uses the element rect if the whole view is visible" do
        expect(coordinates).to receive(:min_x).and_return(10)
        expect(coordinates).to receive(:element_origin).and_return({x: 20})
        expect(coordinates).to receive(:element_center).and_return({y: -1})

        actual = coordinates.left_point_for_full_view_pan
        expect(actual[:x]).to be == 30
        expect(actual[:y]).to be == -1
      end

      it "uses min_x if element rect is partially off the screen" do
        expect(coordinates).to receive(:min_x).and_return(10)
        expect(coordinates).to receive(:element_origin).and_return({x: -30})
        expect(coordinates).to receive(:element_center).and_return({y: -1})

        actual = coordinates.left_point_for_full_view_pan
        expect(actual[:x]).to be == 10
        expect(actual[:y]).to be == -1
      end
    end

    context "#right_point_for_full_view_pan" do
      it "uses the element rect if the whole view is visible" do
        expect(coordinates).to receive(:max_x).and_return(320)
        expect(coordinates).to receive(:element_origin).and_return({x: 20})
        expect(coordinates).to receive(:element_size).and_return({width: 200})
        expect(coordinates).to receive(:element_center).and_return({y: -1})

        actual = coordinates.right_point_for_full_view_pan
        expect(actual[:x]).to be == 210
        expect(actual[:y]).to be == -1
      end

      it "uses max_x if element is partially off the screen" do
        expect(coordinates).to receive(:max_x).and_return(320)
        expect(coordinates).to receive(:element_origin).and_return({x: 20})
        expect(coordinates).to receive(:element_size).and_return({width: 320})
        expect(coordinates).to receive(:element_center).and_return({y: -1})

        actual = coordinates.right_point_for_full_view_pan
        expect(actual[:x]).to be == 320
        expect(actual[:y]).to be == -1
      end
    end

    context "#top_point_for_full_view_pan" do
      it "uses the element rect if the whole view is visible" do
        expect(coordinates).to receive(:min_y).and_return(80)
        expect(coordinates).to receive(:element_origin).and_return({y: 100})
        expect(coordinates).to receive(:element_center).and_return({x: -1})

        actual = coordinates.top_point_for_full_view_pan
        expect(actual[:x]).to be == -1
        expect(actual[:y]).to be == 110
      end

      it "uses min_y if element is partially off the screen or under a bar" do
        expect(coordinates).to receive(:min_y).and_return(80)
        expect(coordinates).to receive(:element_origin).and_return({y: 0})
        expect(coordinates).to receive(:element_center).and_return({x: -1})

        actual = coordinates.top_point_for_full_view_pan
        expect(actual[:x]).to be == -1
        expect(actual[:y]).to be == 80
      end
    end

    context "#bottom_point_for_full_view_pan" do
      it "uses the element rect if the whole view is visible" do
        expect(coordinates).to receive(:max_y).and_return(600)
        expect(coordinates).to receive(:element_origin).and_return({y: 0})
        expect(coordinates).to receive(:element_size).and_return({:height => 200})
        expect(coordinates).to receive(:element_center).and_return({x: -1})

        actual = coordinates.bottom_point_for_full_view_pan
        expect(actual[:x]).to be == -1
        expect(actual[:y]).to be == 190
      end

      it "uses max_y if element is partially off the screen or under a bar" do
        expect(coordinates).to receive(:max_y).and_return(600)
        expect(coordinates).to receive(:element_origin).and_return({y: 0})
        expect(coordinates).to receive(:element_size).and_return({:height => 680})
        expect(coordinates).to receive(:element_center).and_return({x: -1})

        actual = coordinates.bottom_point_for_full_view_pan
        expect(actual[:x]).to be == -1
        expect(actual[:y]).to be == 600
      end
    end

    context "#points_for_full_view_pan" do
      it "raises an exception if direction is not valid" do
        expect do
          coordinates.points_for_full_view_pan(:sideways)
        end.to raise_error ArgumentError, /is not supported/
      end

      context "valid directions" do
        it ":left" do
          expect(coordinates).to receive(:right_point_for_full_view_pan).and_return(:start)
          expect(coordinates).to receive(:left_point_for_full_view_pan).and_return(:end)

          actual = coordinates.points_for_full_view_pan(:left)
          expect(actual[:start]).to be == :start
          expect(actual[:end]).to be == :end
        end

        it ":right" do
          expect(coordinates).to receive(:left_point_for_full_view_pan).and_return(:start)
          expect(coordinates).to receive(:right_point_for_full_view_pan).and_return(:end)

          actual = coordinates.points_for_full_view_pan(:right)
          expect(actual[:start]).to be == :start
          expect(actual[:end]).to be == :end
        end

        it ":up" do
          expect(coordinates).to receive(:bottom_point_for_full_view_pan).and_return(:start)
          expect(coordinates).to receive(:top_point_for_full_view_pan).and_return(:end)

          actual = coordinates.points_for_full_view_pan(:up)
          expect(actual[:start]).to be == :start
          expect(actual[:end]).to be == :end
        end

        it ":down" do
          expect(coordinates).to receive(:top_point_for_full_view_pan).and_return(:start)
          expect(coordinates).to receive(:bottom_point_for_full_view_pan).and_return(:end)

          actual = coordinates.points_for_full_view_pan(:down)
          expect(actual[:start]).to be == :start
          expect(actual[:end]).to be == :end
        end
      end
    end

    context "#left_point_for_half_view_pan" do
      it "uses the element rect if the whole view is visible"
      it "uses min_x if element rect is partially off the screen"
    end

    context "#right_point_for_half_view_pan" do
      it "uses the element rect if the whole view is visible"
      it "uses max_x if element is partially off the screen"
    end

    context "#top_point_for_half_view_pan" do
      it "uses the element rect if the whole view is visible"
      it "uses min_y if element is partially off the screen or under a bar"
    end

    context "#bottom_point_for_half_view_pan" do
      it "uses the element rect if the whole view is visible"
      it "uses max_y if element is partially off the screen or under a bar"
    end

    context "#points_for_half_view_pan" do
      it "raises an exception if direction is not valid"
      context "valid directions" do
        it ":left"
        it ":right"
        it ":up"
        it ":down"
      end
    end

    context "#left_point_for_small_view_pan" do
      it "uses the element rect if the whole view is visible"
      it "uses min_x if element rect is partially off the screen"
    end

    context "#right_point_for_small_view_pan" do
      it "uses the element rect if the whole view is visible"
      it "uses max_x if element is partially off the screen"
    end

    context "#top_point_for_small_view_pan" do
      it "uses the element rect if the whole view is visible"
      it "uses min_y if element is partially off the screen or under a bar"
    end

    context "#bottom_point_for_small_view_pan" do
      it "uses the element rect if the whole view is visible"
      it "uses max_y if element is partially off the screen or under a bar"
    end

    context "#points_for_small_view_pan" do
      it "raises an exception if direction is not valid"
      context "valid directions" do
        it ":left"
        it ":right"
        it ":up"
        it ":down"
      end
    end
  end

  context "private methods" do
    it "#element_center" do
      actual = coordinates.send(:element_center)
      expect(actual[:x]).to be == row["rect"]["center_x"]
      expect(actual[:y]).to be == row["rect"]["center_y"]
      expect(coordinates.instance_variable_get(:@element_center)).to be == actual
    end

    it "#element_origin" do
      actual = coordinates.send(:element_origin)
      expect(actual[:x]).to be == row["rect"]["x"]
      expect(actual[:y]).to be == row["rect"]["y"]
      expect(coordinates.instance_variable_get(:@element_origin)).to be == actual
    end

    it "#element_size" do
      actual = coordinates.send(:element_size)
      expect(actual[:height]).to be == row["rect"]["height"]
      expect(actual[:width]).to be == row["rect"]["width"]
      expect(coordinates.instance_variable_get(:@element_size)).to be == actual
    end

    context "#height_for_view" do
      it "returns the height if the element exists" do
        expect(coordinates).to receive(:query_wrapper).with("Class").and_return([row])

        actual = coordinates.send(:height_for_view, "Class")
        expect(actual).to be == row["rect"]["height"]
      end

      it "returns 0 if the element does not exist" do
        expect(coordinates).to receive(:query_wrapper).with("Class").and_return([])

        actual = coordinates.send(:height_for_view, "Class")
        expect(actual).to be == 0
      end
    end

    it "#status_bar_height" do
      hash = {"frame" => { "height" => 4 } }
      expect(coordinates).to receive(:status_bar_details).and_return(hash)

      actual = coordinates.send(:status_bar_height)
      expect(actual).to be == hash["frame"]["height"]
      expect(coordinates.instance_variable_get(:@status_bar_height)).to be == actual
    end

    it "#nav_bar_height" do
      expect(coordinates).to receive(:height_for_view).with("UINavigationBar").and_return(1)

      actual = coordinates.send(:nav_bar_height)
      expect(actual).to be == 1
      expect(coordinates.instance_variable_get(:@nav_bar_height)).to be == actual
    end

    it "#tab_bar_height" do
      expect(coordinates).to receive(:height_for_view).with("UITabBar").and_return(1)

      actual = coordinates.send(:tab_bar_height)
      expect(actual).to be == 1
      expect(coordinates.instance_variable_get(:@tab_bar_height)).to be == actual
    end

    it "#toolbar_height" do
      expect(coordinates).to receive(:height_for_view).with("UIToolbar").and_return(1)

      actual = coordinates.send(:toolbar_height)
      expect(actual).to be == 1
      expect(coordinates.instance_variable_get(:@toolbar_height)).to be == actual
    end

    it "#window" do
      expect(coordinates).to receive(:query_wrapper).with("*").and_return([window])

      actual = coordinates.send(:window)
      expect(actual[:height]).to be == window["rect"]["height"]
      expect(actual[:width]).to be == window["rect"]["width"]
      expect(actual[:center_x]).to be == window["rect"]["center_x"]
      expect(actual[:center_y]).to be == window["rect"]["center_y"]
      expect(coordinates.instance_variable_get(:@window)).to be == actual
    end

    it "#min_y" do
      expect(coordinates).to receive(:status_bar_height).and_return(2)
      expect(coordinates).to receive(:nav_bar_height).and_return(3)

      actual = coordinates.send(:min_y)
      expect(actual).to be == 21
      expect(coordinates.instance_variable_get(:@min_y)).to be == actual
    end

    it "#max_y" do
      expect(coordinates).to receive(:window).and_return({:height => 100})
      expect(coordinates).to receive(:tab_bar_height).and_return(2)
      expect(coordinates).to receive(:toolbar_height).and_return(2)

      actual = coordinates.send(:max_y)
      expect(actual).to be == 80
      expect(coordinates.instance_variable_get(:@max_y)).to be == actual
    end

    it "#max_x" do
      expect(coordinates).to receive(:window).and_return({:width => 100})

      actual = coordinates.send(:max_x)
      expect(actual).to be == 90
      expect(coordinates.instance_variable_get(:@max_x)).to be == actual
    end
  end
end
