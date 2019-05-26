
describe Calabash::Cucumber::Map do
  RSpec::Expectations.configuration.warn_about_potential_false_positives = false
  let(:query) { "view marked:'my mark'" }
  let(:method_name) { :scrollToViewWithMark }
  let(:args) { ["arg0", "arg1", "arg2"] }
  let(:map) { Calabash::Cucumber::Map.new }
  let(:correct_predicate) {Calabash::Cucumber::Map::VALID_PREDICATES}

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

  describe ".raw_map" do
    let(:query) { "view marked:'my mark'" }
    let(:incorrect_predicate) {['BEGINSWTH', 'CONTAIN', 'ENDWITH', 'LKE' 'MTCHES']}

    it "receive incorrect predicate operation and raise error" do

      incorrect_predicate.each do |predicate|
        merged_query = query + "{text #{predicate} 'sometext'}"
        expect do
          Calabash::Cucumber::Map.raw_map(merged_query, method_name, args)
        end.to raise_error(RuntimeError,
                           /Incorrect predicate used, valid operation are:/)
      end

    end

    it "receive correct predicate operation but incomplete string and raise error" do

      correct_predicate.each do |predicate|
        merged_query = query + "{text #{predicate} 'sometext}"
        expect do
          Calabash::Cucumber::Map.raw_map(merged_query, method_name, args)
        end.to raise_error(RuntimeError,
                           /Incorrect predicate used, valid operation are:/)
      end

    end

    it "raw_map receive correct predicate and not raise error" do

      correct_predicate.each do |predicate|
        merged_query = query + "{text #{predicate} 'sometext'}"
        expect do
          Calabash::Cucumber::Map.raw_map(merged_query, method_name, args)
        end.not_to raise_error(RuntimeError)
      end

    end
  end

  describe ".correct_predicate?" do
    let(:query) { "view" }

    it "receive query without predicate and return nil" do
      expect(Calabash::Cucumber::Map.correct_predicate?(query)).to be nil
    end

    it "receive query with correct predicate and return true" do
      correct_predicate_operation = ["{text BEGINSWITH 'Cell 1'}",
                                     "{text ENDSWITH '10'}",
                                     "{text LIKE 'C*ll'}",
                                     "{text CONTAINS 'ell'}",
                                     "{text > 'ell'}",
                                     "{text < 'ell'}"]
      correct_predicate_operation.each do |predicate|
        merged_query = query + predicate
        expect(Calabash::Cucumber::Map.correct_predicate?(merged_query)).to be true
      end
    end

    it "receive query with incorrect predicate operation and raise error" do
      test_data = ["{text BEGINWITH 'Cell 1'}",
                   "{text ENDSITH '10'}",
                   "{text LIK 'C*ll'}",
                   "{text CONTAIN 'ell'}",
                   "{text = 'ell'}",
                   "{text - 'ell'}"]
      test_data.each do |predicate|
        merged_query = query + predicate
        expect do
          Calabash::Cucumber::Map.correct_predicate?(merged_query)
        end.to raise_error(RuntimeError)
      end
    end

    it "receive query with correct predicate operation \
        but incomplete string and raise error" do
      test_data = ["{text BEGINSWITH Cell 1'}",
                   "{text BEGINSWITH 'Cell 1}",
                   "{text ENDSWITH 10'}",
                   "{text ENDSWITH '10}",
                   "{text LIKE C*ll'}",
                   "{text LIKE 'C*ll}",
                   "{text CONTAINS ell'}",
                   "{text CONTAINS 'ell}",
                   "{text > ell'}",
                   "{text > 'ell}",
                   "{text < ell'}",
                   "{text < 'ell}"]
      test_data.each do |predicate|
        merged_query = query + predicate
        expect do
          Calabash::Cucumber::Map.correct_predicate?(merged_query)
        end.to raise_error(RuntimeError)
      end
    end

    it "receive query with correct predicate operation \
        and diacritic lookups and return true" do
      lookup = ['c', 'd', 'cd']
      correct_predicate.each do |predicate|
        lookup.each do |item|
          merged_query = query + "{text #{predicate}[#{item}] 'sometext'}"
          expect(Calabash::Cucumber::Map.correct_predicate?(merged_query)).to be true
        end
      end
    end

    it "receive query with correct predicate operation \
        and diacritic lookup but incomplete string and raise error" do
      lookup = ['c', 'd', 'cd']
      correct_predicate.each do |predicate|
        lookup.each do |item|
          merged_query = query + "{text #{predicate}[#{item}] 'sometext}"
          expect do
            Calabash::Cucumber::Map.correct_predicate?(merged_query)
          end.to raise_error(RuntimeError)
        end
      end
    end
  end

  describe ".correct_format?" do
    let(:query) { "view" }

    it "receive query with predicate and return nil" do
      merged_query = query + "{text BEGINSWITH 'Cell 1'}"
      expect(Calabash::Cucumber::Map.correct_format?(merged_query)).to be nil
    end

    it "receive query without predicate and return true" do
      expect(Calabash::Cucumber::Map.correct_format?(query)).to be true
    end

    it "receive query with id and return true" do
      merged_query = query + "id:'some_id'"
      expect(Calabash::Cucumber::Map.correct_format?(merged_query)).to be true
    end

    it "receive query with id and incomplete sting and raise error" do
      merged_query = query + "id:'some_id"
      expect do
        Calabash::Cucumber::Map.correct_format?(merged_query)
      end.to raise_error(RuntimeError)
    end
  end

end

