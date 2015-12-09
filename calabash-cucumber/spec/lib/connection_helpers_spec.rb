describe Calabash::Cucumber::ConnectionHelpers do

  let(:world) do
    Class.new do
      include Calabash::Cucumber::ConnectionHelpers
    end.new
  end

  let(:response_error) { Calabash::Cucumber::ResponseError }

  describe "#response_body_to_hash" do
    let(:success_body) { "{\"results\":1,\"result\":1,\"outcome\":\"SUCCESS\"}" }
    let(:failure_hash) do
      {
        "outcome" => "FAILURE",
        "details" => "The sordid details",
        "reason" => "Just the facts"
      }
    end

    let(:failure_body) { JSON.generate(failure_hash) }

    it "SUCCESS" do
      hash = world.response_body_to_hash(success_body)
      expect(hash["result"]).to be == 1
    end

    describe "FAILURE" do
      it "has reason and details" do
        hash = world.response_body_to_hash(failure_body)

        expect(hash["reason"]).to be == "Just the facts"
        expect(hash["details"]).to be == "The sordid details"
        expect(hash["outcome"]).to be == "FAILURE"
      end

      it "has no reason" do
        failure_hash[:reason] = nil

        hash = world.response_body_to_hash(failure_body)

        expect(hash["reason"]).to be == "Server provided no reason."
        expect(hash["details"]).to be == "The sordid details"
        expect(hash["outcome"]).to be == "FAILURE"
      end

      it "hash no details" do
        failure_hash[:details] = nil

        hash = world.response_body_to_hash(failure_body)

        expect(hash["reason"]).to be == "Just the facts"
        expect(hash["details"]).to be == "Server provided no details."
        expect(hash["outcome"]).to be == "FAILURE"
      end
    end

    describe "raises errors" do
      describe "when body is empty" do
        it "body is nil" do
          expect do
            world.response_body_to_hash(nil)
          end.to raise_error response_error, /Server replied with an empty response/
        end

        it "body is the empty string" do
          expect do
            world.response_body_to_hash("")
          end.to raise_error response_error, /Server replied with an empty response/
        end
      end

      describe "when JSON jcannot parse body" do
        it "TypeError" do
          expect(JSON).to receive(:parse).with(success_body).and_raise TypeError

          expect do
            world.response_body_to_hash(success_body)
          end.to raise_error response_error, /Could not parse server response/
        end

        it "JSON::ParserError" do
          expect(JSON).to receive(:parse).with(success_body).and_raise JSON::ParserError

          expect do
            world.response_body_to_hash(success_body)
          end.to raise_error response_error, /Could not parse server response/
        end
      end

      it "SUCCESS response has no results key" do
        hash = { "outcome" => "SUCCESS" }
        expect(JSON).to receive(:parse).with(success_body).and_return(hash)

        expect do
          world.response_body_to_hash(success_body)
        end.to raise_error response_error, /does not contain 'results' key/
      end

      it "response has invalid outcome" do
        hash = { "outcome" => "an invalid outcome" }
        expect(JSON).to receive(:parse).with(success_body).and_return(hash)

        expect do
          world.response_body_to_hash(success_body)
        end.to raise_error response_error, /Server responded with an invalid outcome/
      end
    end
  end
end

