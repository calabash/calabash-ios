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

  it "#puts_message_of_the_day" do
    out = capture_stdout do
      console.puts_message_of_the_day
    end.string.gsub(/\e\[(\d+)m/, "")

    expect(out[/Calabash says,/, 0]).to be_truthy
  end

  describe "verbose and quiet" do
    let(:original_debug) { ENV["DEBUG"] }

    describe "#verbose" do
      it "already on" do
        expect(RunLoop::Environment).to receive(:debug?).and_return(true)
        console.verbose
      end

      it "turns it on" do
        expect(RunLoop::Environment).to receive(:debug?).and_return(false)
        console.verbose
        expect(ENV["DEBUG"]).to be == "1"
      end
    end

    describe "#quiet" do
      it "already off" do
        expect(RunLoop::Environment).to receive(:debug?).and_return(false)
        console.quiet
      end

      it "turns it off" do
        expect(RunLoop::Environment).to receive(:debug?).and_return(true)
        console.quiet
        expect(ENV["DEBUG"]).to be == "0"
      end
    end

    after do
      ENV["DEBUG"] = original_debug
    end
  end

  it "#copy" do
    require "calabash-cucumber/console_helpers"
    expect(Calabash::Cucumber::ConsoleHelpers).to receive(:copy).and_return(:copied)

    expect(console.copy).to be == :copied
  end

  it "#clear_clipboard" do
    require "calabash-cucumber/console_helpers"
    expect(Calabash::Cucumber::ConsoleHelpers).to receive(:clear_clipboard!).and_return(:cleared)

    expect(console.clear_clipboard).to be == :cleared
  end

  it "#clear" do
    require "calabash-cucumber/console_helpers"
    expect(Calabash::Cucumber::ConsoleHelpers).to receive(:clear).and_return(:cleared)

    expect(console.clear).to be == :cleared
  end

  it "#print_marks" do
    console.send(:print_marks, ids, 29)
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

    it ".copy" do
      require "clipboard"
      mod = Calabash::Cucumber::ConsoleHelpers
      history = ["a", "b", "c"]
      filtered = ["a", "b"]
      expect(mod).to receive(:current_console_history).and_return(history)
      expect(mod).to receive(:filter_commands).with(history).and_return(filtered)
      expect(Clipboard).to receive(:copy).with("a#{$-0}b").and_return(:copied)

      expect(mod.send(:copy)).to be == true
    end

    it ".clear_clipboard!" do
      require "clipboard"
      mod = Calabash::Cucumber::ConsoleHelpers
      expect(mod).to receive(:readline_history).and_return(:history)
      expect(Clipboard).to receive(:clear).and_return("")

      expect(mod.send(:clear_clipboard!)).to be == true
      expect(mod.class_variable_get(:@@start_readline_history)).to be == :history
    end

    describe ".clear" do
      it "windows env" do
        mod = Calabash::Cucumber::ConsoleHelpers
        expect(RunLoop::Environment).to receive(:windows_env?).and_return(true)
        expect(mod).to receive(:system_clear).with("cls").and_return(:true)

        expect(mod.send(:clear)).to be == true
      end

      it "non-windows" do
        mod = Calabash::Cucumber::ConsoleHelpers
        expect(RunLoop::Environment).to receive(:windows_env?).and_return(false)
        expect(mod).to receive(:system_clear).with("clear").and_return(:true)

        expect(mod.send(:clear)).to be == true
      end
    end

    it ".current_console_history" do
      mod = Calabash::Cucumber::ConsoleHelpers
      readline_history = ["a", "b", "c", "d"]
      variable_history = ["c", "d"]
      mod.class_variable_set(:@@start_readline_history, variable_history)
      expect(mod).to receive(:readline_history).and_return(readline_history)

      expect(mod.send(:current_console_history)).to be == ["c", "d"]
    end

    it ".filter_commands" do
      commands = [
        "tree",
        "flash",
        "ids",
        "labels",
        "text",
        "marks",
        "verbose",
        "query",
        "touch",
        "quiet",
        "clear",
        "clear_clipboard",
        "copy",
        "start_test_server_in_background",
        "exit"
      ]

      mod = Calabash::Cucumber::ConsoleHelpers
      expected = ["query", "touch"]
      expect(mod.send(:filter_commands, commands)).to be == expected
    end

    describe ".start_readline_history!" do
      let(:conf) do
        {
          :HISTORY_FILE => ".irb-history"
        }
      end

      before do
        require "irb"
        require "calabash-cucumber/console_helpers"
        allow(IRB).to receive(:conf).and_return(conf)
      end

      it "initializes @@start_readline_history to empty array if no history file" do
        expect(File).to receive(:exist?).with(conf[:HISTORY_FILE]).and_return(false)

        mod = Calabash::Cucumber::ConsoleHelpers
        mod.start_readline_history!
        expect(mod.class_variable_get(:@@start_readline_history)).to be == []
      end

      it "reads contents of history and initializes @@start_readline_history" do
        dir = Resources.shared.resources_dir
        file = File.join(dir, "console", "history-with-non-utf8.log")
        conf[:HISTORY_FILE] = file

        mod = Calabash::Cucumber::ConsoleHelpers
        mod.start_readline_history!
        actual = mod.class_variable_get(:@@start_readline_history)

        expect(actual[0]).to be == "  PID COMMAND"
        expect(actual[1]).to be == "  324 /usr/libexec/UserEventAgent (Aqua)"
        expect(actual[2]).to be == "  403 /Applications/M^\\M^IM^AM^SM^MM^E.app/Contents/MacOS/M^\\M^IM^AM^SM^MM^E"
        expect(actual[3]).to be == " 1497 irb"
      end
    end

    describe ".encode_utf8_or_raise" do
      let(:string) { "string" }
      let(:encoded) { "encoded" }
      let(:forced) { "forced" }
      let(:mod) { Calabash::Cucumber::ConsoleHelpers }

      before do
        require "calabash-cucumber/console_helpers"
      end

      it "returns '' if string arg is falsey" do
        expect(mod.send(:encode_utf8_or_raise, nil)).to be == ''
      end

      it "returns utf8 encoding" do
        expect(string).to receive(:force_encoding).with("UTF-8").and_return(encoded)
        expect(encoded).to receive(:chomp).and_return(encoded)
        expect(encoded).to receive(:valid_encoding?).and_return(true)

        expect(mod.send(:encode_utf8_or_raise, string)).to be == encoded
      end

      it "forces utf8 encoding" do
        expect(string).to receive(:force_encoding).with("UTF-8").and_return(encoded)
        expect(encoded).to receive(:chomp).and_return(encoded)
        expect(encoded).to receive(:valid_encoding?).and_return(false)
        expect(encoded).to receive(:encode).and_return(forced)
        expect(forced).to receive(:valid_encoding?).and_return(true)

        expect(mod.send(:encode_utf8_or_raise, string)).to be == forced
      end

      it "raises an error if string cannot be coerced to UTF8" do
        expect(string).to receive(:force_encoding).with("UTF-8").and_return(encoded)
        expect(encoded).to receive(:chomp).and_return(encoded)
        expect(encoded).to receive(:valid_encoding?).and_return(false)
        expect(encoded).to receive(:encode).and_return(forced)
        expect(forced).to receive(:valid_encoding?).and_return(false)

        expect do
          mod.send(:encode_utf8_or_raise, string)
        end.to raise_error RuntimeError,
                           /Could not force UTF-8 encoding on this string:/
      end

      it "handles string with non-UTF8 characters" do
        dir = Resources.shared.resources_dir
        file = File.join(dir, "console", "history-with-non-utf8.log")
        string = File.read(file)
        actual = mod.send(:encode_utf8_or_raise, string)
        split = actual.split($-0)

        expect(split[0]).to be == "  PID COMMAND"
        expect(split[1]).to be == "  324 /usr/libexec/UserEventAgent (Aqua)"
        expect(split[2]).to be == "  403 /Applications/M^\\M^IM^AM^SM^MM^E.app/Contents/MacOS/M^\\M^IM^AM^SM^MM^E"
        expect(split[3]).to be == " 1497 irb"
      end
    end
  end
end
