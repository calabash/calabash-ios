describe "Calabash::Cucumber::ConsoleHelpers" do

  let(:console) do
    Class.new do
      require "calabash-cucumber/console_helpers"
      include Calabash::Cucumber::ConsoleHelpers
      def to_s; "#<Calabash iOS Console>"; end
      def inspect; to_s; end
      def query(_, *_); ; ; end
      def http(_); ; ; end
    end.new
  end

  let(:ids) do
    [["CalViewWithArbitrarySelectors", "controls page"],
     ["UITextField", "text"],
     ["UISlider", "slider"],
     ["UISwitch", "switch"],
     ["UITabBarSwappableImageView", "tab-bar-controls"],
     ["UITabBarSwappableImageView", "tab-bar-gestures"],
     ["UITabBarSwappableImageView", "tab-bar-scrolling"],
     ["UITabBarSwappableImageView", "tab-bar-special"],
     ["UITabBarSwappableImageView", "tab-bar-elephant"]]
  end

  let(:labels) do
    [["CalViewWithArbitrarySelectors", "UI controls"],
     ["UITabBarButton", "Controls"],
     ["UITabBarButtonLabel", "Controls"],
     ["UITabBarButton", "Gestures"],
     ["UITabBarButtonLabel", "Gestures"],
     ["UITabBarButton", "Scrolls"],
     ["UITabBarButtonLabel", "Scrolls"],
     ["UITabBarButton", "Special"],
     ["UITabBarButtonLabel", "Special"],
     ["UITabBarButton", "Date Picker"],
     ["UITabBarButtonLabel", "Date Picker"]]
  end

  let(:texts) do
    [["UITabBarButtonLabel", "Controls"],
     ["UITabBarButtonLabel", "Gestures"],
     ["UITabBarButtonLabel", "Scrolls"],
     ["UITabBarButtonLabel", "Special"],
     ["UITabBarButtonLabel", "Date Picker"]]
  end

  let(:query_result) do
    # We need to use "oj" parser because:
    #
    # JSON.parse(JSON.generate(query("*")))
    #
    # is failing although the JSON is valid according to JSONLint and other
    # sources.
    require "oj"
    dir = Resources.shared.resources_dir
    path = File.join(dir, "console", "query_result.json")
    Oj.load_file(path)
  end

  let(:query_text_result) do
    # We need to use "oj" parser because:
    #
    # JSON.parse(JSON.generate(query("*")))
    #
    # is failing although the JSON is valid according to JSONLint and other
    # sources.
    require "oj"
    dir = Resources.shared.resources_dir
    path = File.join(dir, "console", "query_text_result.json")
    Oj.load_file(path)
  end

  let(:dump_json) do
    dir = Resources.shared.resources_dir
    File.join(dir, "console", "dump.json")
  end

  let(:dump_hash) do
    JSON.parse(File.read(dump_json))
  end

  it "#tree" do
    expect(console).to receive(:http_fetch_view_hierarchy).and_return(dump_hash)
    expect(console).to receive(:dump_json_data).with(dump_hash).and_call_original

    actual = nil
    out = capture_stdout do
      actual = console.tree
    end.string.gsub(/\e\[(\d+)m/, "")

    expect(actual).to be == true
    regex = /        \[CalViewWithArbitrarySelectors\] \[id:controls page\] \[label:UI controls\]/
    expect(out[regex, 0]).to be_truthy
    regex = /        \[UITabBarButtonLabel\] \[label:Date Picker\] \[text:Date Picker\]/
    expect(out[regex, 0]).to be_truthy
  end

  it "#ids" do
    expect(console).to receive(:accessibility_marks).with(:id).and_return([:ids])

    expect(console.ids).to be == [:ids]
  end

  it "#labels" do
    expect(console).to receive(:accessibility_marks).with(:label).and_return([:labels])

    expect(console.labels).to be == [:labels]
  end

  it "#text" do
    expect(console).to receive(:text_marks).and_return([:text])

    expect(console.text).to be == [:text]
  end

  it "#marks" do
    options = { :print => false, :return => true }
    expect(console).to receive(:accessibility_marks).with(:id, options).and_return(ids)
    expect(console).to receive(:accessibility_marks).with(:label, options).and_return(labels)
    expect(console).to receive(:text_marks).with(options).and_return(texts)

    actual = nil
    out = capture_stdout do
      actual = console.marks
    end.string

    expect(actual).to be_truthy
    expect(out[/ \[0\] label  => CalViewWithArbitrarySelectors => UI controls/, 0]).to be_truthy
    expect(out[/\[10\] text   =>           UITabBarButtonLabel => Controls/, 0]).to be_truthy
    expect(out[/\[24\] id     =>                   UITextField => text/, 0]).to be_truthy
  end

  it "#print_marks" do
    console.send(:print_marks, ids, 29)
  end

  it "#puts_message_of_the_day" do
    out = capture_stdout do
      console.puts_message_of_the_day
    end.string.gsub(/\e\[(\d+)m/, "")

    expect(out[/Calabash says,/, 0]).to be_truthy
  end

  describe "accessibility_marks" do
    let(:options) { {:print => false, :return => true} }

    before do
      allow(console).to receive(:query).with("*").and_return(query_result)
    end

    it "raises error when kind is not valid" do
      expect do
        console.send(:accessibility_marks, :unknown)
      end.to raise_error ArgumentError, /is not one of/
    end

    describe "parsing query results" do
      it ":id" do
        actual = console.send(:accessibility_marks, :id, options)
        expect(actual).to be == ids
      end

      it ":labels" do
        actual = console.send(:accessibility_marks, :label, options)
        expect(actual).to be == labels
      end
    end

    describe "default options" do
      let(:options) { {} }

      it "returns true if options[:return] is falsey (default)" do
        options[:print] = false
        expect(console.send(:accessibility_marks, :id, options)).to be_truthy
        expect(console.send(:accessibility_marks, :label, options)).to be_truthy
      end

      it "return prints results if options[:print] is truthy (default)" do
        expect(console).to receive(:print_marks).with(ids, 29).and_call_original
        out = capture_stdout do
          console.send(:accessibility_marks, :id, options)
        end.string

        expect(out[/\[0\]   CalViewWithArbitrarySelectors => controls page/, 0]).to be_truthy
        expect(out[/\[8\]                     UITextField => text/, 0]).to be_truthy

        expect(console).to receive(:print_marks).with(labels, 29).and_call_original
        out = capture_stdout do
          console.send(:accessibility_marks, :label, options)
        end.string

        expect(out[/ \[0\]   CalViewWithArbitrarySelectors => UI controls/, 0]).to be_truthy
        expect(out[/\[10\]             UITabBarButtonLabel => Special/, 0]).to be_truthy
      end
    end
  end

  describe "accessibility_marks" do
    let(:options) { {:print => false, :return => true} }

    before do
      allow(console).to receive(:query).with("*").and_return(query_result)
      allow(console).to receive(:query).with("*", :text).and_return(query_text_result)
    end

    it "merges query and query :text" do
      actual = console.send(:text_marks, options)
      expect(actual).to be == texts
    end

    describe "default options" do
      let(:options) { {} }

      it "returns true if options[:return] is falsey (default)" do
        options[:print] = false
        expect(console.send(:text_marks, options)).to be_truthy
      end

      it "return prints results if options[:print] is truthy (default)" do
        expect(console).to receive(:print_marks).with(texts, 19).and_call_original
        out = capture_stdout do
          console.send(:text_marks, options)
        end.string

        expect(out[/\[0\]   UITabBarButtonLabel => Controls/, 0]).to be_truthy
        expect(out[/\[4\]   UITabBarButtonLabel => Special/, 0]).to be_truthy
      end
    end

    describe "#http_fetch_view_hierarchy" do
      let(:route) { {method: :get, path: "dump"} }

      describe "raises errors" do
        it "nil body" do
          expect(console).to receive(:http).with(route).and_return(nil)

          expect do
            console.send(:http_fetch_view_hierarchy)
          end.to raise_error(Calabash::Cucumber::ResponseError,
                             /Server replied with an empty response/)
        end

        it "empty body" do
          expect(console).to receive(:http).with(route).and_return("")

          expect do
            console.send(:http_fetch_view_hierarchy)
          end.to raise_error(Calabash::Cucumber::ResponseError,
                             /Server replied with an empty response/)
        end

        describe "JSON parse error" do

          before do
            expect(console).to receive(:http).with(route).and_return(dump_json)
          end

          it "TypeError" do
            expect(JSON).to receive(:parse).with(dump_json).and_raise TypeError

            expect do
              console.send(:http_fetch_view_hierarchy)
            end.to raise_error(Calabash::Cucumber::ResponseError,
                               /Could not parse server response/)
          end

          it "JSON::ParserError" do
            expect(JSON).to receive(:parse).with(dump_json).and_raise JSON::ParserError

            expect do
              console.send(:http_fetch_view_hierarchy)
            end.to raise_error(Calabash::Cucumber::ResponseError,
                               /Could not parse server response/)
          end
        end
      end

      it "parses json" do
        expect(console).to receive(:http).with(route).and_return(dump_json)
        expect(JSON).to receive(:parse).with(dump_json).and_return(:parsed)

        expect(console.send(:http_fetch_view_hierarchy)).to be == :parsed
      end
    end
  end
end
