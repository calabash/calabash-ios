
describe Calabash::Cucumber::StatusBarHelpers do

  let(:helper) do
    Class.new do
      include Calabash::Cucumber::StatusBarHelpers
    end.new
  end

  context "#status_bar_details" do
    it "returns the results of /statusBar route" do
      reply = JSON.generate({
                              "results" => {
                                "frame" => { },
                                "hidden" => false,
                                "orientation" => "down"
                              }
                            })

      expect(helper).to receive(:http).and_return(reply)
      actual = helper.status_bar_details
      expect(actual["frame"]).to be == {}
      expect(actual["hidden"]).to be == false
      expect(actual["orientation"]).to be == "down"
    end

    context "returns generic values if the /statusBar route is not available" do
      before do
        expect(helper).to receive(:http).and_return("")
      end

      it "returns height 20 for portrait" do
        expect(helper).to receive(:status_bar_orientation).at_least(:once).and_return("down")

        actual = helper.status_bar_details
        expect(actual["frame"]["height"]).to be == 20
        expect(actual["warning"]).to be_truthy
      end

      it "returns height 10 for landscape" do
        expect(helper).to receive(:status_bar_orientation).at_least(:once).and_return("left")

        actual = helper.status_bar_details
        expect(actual["frame"]["height"]).to be == 10
        expect(actual["warning"]).to be_truthy
      end
    end
  end
end
