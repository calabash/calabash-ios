module Calabash
  module Cucumber
    # A collection of methods that help you use console.
    module ConsoleHelpers

      # Print a representation of the current view hierarchy.
      def tree
        hash = http_fetch_view_hierarchy
        dump_json_data(hash)
        true
      end

      # Print the visible element ids.
      def ids
        accessibility_marks(:id)
      end

      # Print the visible element labels.
      def labels
        accessibility_marks(:label)
      end

      # Print the visible element texts.
      def text
        text_marks
      end

      # List the visible element with all marks.
      def marks
        opts = {:print => false, :return => true }
        res = accessibility_marks(:id, opts).each { |elm|elm << :id }
        res.concat(accessibility_marks(:label, opts).each { |elm| elm << :label })
        res.concat(text_marks(opts).each { |elm| elm << :text })
        max_width = 0
        res.each { |elm|
          len = elm[0].length
          max_width = len if len > max_width
        }

        counter = -1
        res.sort.each { |elm|
          printf("%4s %-6s => %#{max_width}s => %s\n",
                 "[#{counter = counter + 1}]",
                 elm[2], elm[0], elm[1])
        }
        true
      end

      # @!visibility private
      #
      # Users should not call this!!!
      #
      # Needs to be called in the .irbrc to ensure good `copy` behavior.
      def self.start_readline_history!
        require "irb"
        file_name = IRB.conf[:HISTORY_FILE]

        if File.exist?(file_name)
          contents = File.read(file_name)
          history = ConsoleHelpers.encode_utf8_or_raise(contents)
          @@start_readline_history = history.split($-0)
        else
          @@start_readline_history = []
        end
      end

      # Copy all the commands entered in the current console session into the OS
      # Clipboard.
      def copy
        ConsoleHelpers.copy
      end

      # Clear the clipboard
      def clear_clipboard
        ConsoleHelpers.clear_clipboard!
      end

      # Clear the console history.
      def clear
        ConsoleHelpers.clear
      end

      # Print a message to the console.
      def puts_message_of_the_day
        messages = [
          "Let's get this done!",
          "Ready to rumble.",
          "Enjoy.",
          "Remember to breathe.",
          "Take a deep breath.",
          "Isn't it time for a break?",
          "Can I get you a coffee?",
          "What is a calabash anyway?",
          "Smile! You are on camera!",
          "Let op! Wild Rooster!",
          "Don't touch that button!",
          "I'm gonna take this to 11.",
          "Console. Engaged.",
          "Your wish is my command.",
          "This console session was created just for you.",
          "Den som jager to harer, får ingen.",
          "Uti, non abuti.",
          "Non Satis Scire",
          "Nullius in verba",
          "Det ka æn jå væer ei jált",
          "Dzień dobry",
          "Jestem tu by ocalić świat"
        ]
        puts RunLoop::Color.green("Calabash says, \"#{messages.shuffle.first}\"")
      end

      # Turn on debug logging.
      def verbose
        if RunLoop::Environment.debug?
          puts RunLoop::Color.cyan("Debug logging is already turned on.")
        else
          ENV["DEBUG"] = "1"
          puts RunLoop::Color.cyan("Turned on debug logging.")
        end

        true
      end

      # Turn off debug logging.
      def quiet
        if RunLoop::Environment.debug?
          ENV["DEBUG"] = "0"
          puts RunLoop::Color.cyan("Turned off debug logging.")
        else
          puts RunLoop::Color.cyan("Debug logging is already turned off.")
        end

        true
      end

      # @!visibility private
      def puts_console_details
        puts ""
        puts RunLoop::Color.magenta("#########################  Useful Methods  ##########################")
        puts RunLoop::Color.cyan("     ids => List all the visible accessibility ids.")
        puts RunLoop::Color.cyan("  labels => List all the visible accessibility labels.")
        puts RunLoop::Color.cyan("    text => List all the visible texts.")
        puts RunLoop::Color.cyan("   marks => List all the visible marks.")
        puts RunLoop::Color.cyan("    tree => The app's visible view hierarchy.")
        puts RunLoop::Color.cyan("   flash => flash(<query>); Disco effect for views matching <query>")
        puts RunLoop::Color.cyan(" verbose => Turn debug logging on.")
        puts RunLoop::Color.cyan("   quiet => Turn debug logging off.")
        puts RunLoop::Color.cyan("    copy => Copy console commands to clipboard.")
        puts RunLoop::Color.cyan("   clear => Clear the console.")
        puts ""
      end

      # @!visibility private
      # Do not call this method directly.
      def _try_to_attach
        begin
          Calabash::Cucumber::HTTP.ping_app
          launcher = Calabash::Cucumber::Launcher.new
          launcher.attach
          puts(RunLoop::Color.green("Attached to: #{launcher}"))
          launcher
        rescue => _
        end
      end

      private

      # List the visible element with given mark(s).
      # @param {Array} marks
      # @param {Integer} max_width
      def print_marks(marks, max_width)
        counter = -1
        marks.sort.each { |elm|
          printf("%4s %#{max_width + 2}s => %s\n", "[#{counter = counter + 1}]", elm[0], elm[1])
        }
      end

      # @!visibility private
      # List the visible element with accessibility marks.
      def accessibility_marks(kind, opts={})
        merged_opts = {:print => true, :return => false}.merge(opts)

        kinds = [:id, :label]
        raise ArgumentError,
              "'#{kind}' is not one of '#{kinds}'" unless kinds.include?(kind)

        results = Array.new
        max_width = 0

        query("*").each { |view|
          aid = view[kind.to_s]
          unless aid.nil? or aid.eql?("")
            cls = view["class"]
            len = cls.length
            max_width = len if len > max_width
            results << [cls, aid]
          end
        }

        if merged_opts[:print]
          print_marks(results, max_width)
        end

        if merged_opts[:return]
          results
        else
          true
        end
      end

      # @!visibility private
      # List the visible element with text marks.
      def text_marks(opts={})
        merged_opts = {:print => true, :return => false}.merge(opts)

        indexes = Array.new
        idx = 0
        all_texts = query("*", :text)
        all_texts.each { |view|
          indexes << idx unless view.eql?("*****") or view.eql?("")
          idx = idx + 1
        }

        results = Array.new

        all_views = query("*")
        max_width = 0
        indexes.each { |index|
          view = all_views[index]
          cls = view["class"]
          text = all_texts[index]
          len = cls.length
          max_width = len if len > max_width
          results << [cls, text]
        }

        if merged_opts[:print]
          print_marks(results, max_width)
        end

        if merged_opts[:return]
          results
        else
          true
        end
      end

      def http_fetch_view_hierarchy
        require "json"
        response_body = http({:method => :get, :path => "dump"})

        if response_body.nil? || response_body == ""
          raise ResponseError,
                "Server replied with an empty response.  Your app has probably crashed"
        end

        begin
          hash = JSON.parse(response_body)
        rescue TypeError, JSON::ParserError => e
          raise ResponseError,  %Q{Could not parse server response:

#{e}

There was a problem parsing your app's view hierarchy.

Please report this issue.
}
        end

        hash
      end

      def dump_json_data(json_data)
        json_data["children"].each {|child| write_child(child)}
      end

      def write_child(data, indentation=0)
        render(data, indentation)
        data["children"].each do |child|
          write_child(child, indentation+1)
        end
      end

      def render(data, indentation)
        if visible?(data)
          type = data["type"]

          str_type = if data["type"] == "dom"
            "#{RunLoop::Color.cyan("[")}#{type}:#{RunLoop::Color.cyan("#{data["nodeName"]}]")} "
          else
            RunLoop::Color.cyan("[#{type}] ")
          end

          str_id = data["id"] ? "[id:#{RunLoop::Color.blue(data["id"])}] " : ""
          str_label = data["label"] ? "[label:#{RunLoop::Color.green(data["label"])}] " : ""
          str_text = data["value"] ? "[text:#{RunLoop::Color.magenta(data["value"])}] " : ""
          str_node_type = data["nodeType"] ? "[nodeType:#{RunLoop::Color.red(data["nodeType"])}] " : ""

          output("#{str_type}#{str_id}#{str_label}#{str_text}#{str_node_type}", indentation)
          output("\n", indentation)
        end
      end

      def visible?(data)
        (data["visible"] == 1) || data["children"].map{|child| visible?(child)}.any?
      end

      def output(string, indentation)
        (indentation*2).times {print " "}
        print "#{string}"
      end

      # @!visibility private
      def self.copy
        require "clipboard"
        history = ConsoleHelpers.current_console_history
        commands = ConsoleHelpers.filter_commands(history)
        string = commands.join($-0)
        Clipboard.copy(string)
        true
      end

      # @!visibility private
      def self.clear_clipboard!
        require "clipboard"
        @@start_readline_history = ConsoleHelpers.readline_history
        Clipboard.clear
        true
      end

      # @!visibility private
      def self.clear
        if RunLoop::Environment.windows_env?
          ConsoleHelpers.system_clear("cls")
        else
          ConsoleHelpers.system_clear("clear")
        end
        true
      end

      # @!visibility private
      def self.system_clear(command)
        system(command)
      end

      # @!visibility private
      def self.current_console_history
        readline_history = ConsoleHelpers.readline_history
        length = readline_history.length - @@start_readline_history.length

        readline_history.last(length)
      end

      # @!visibility private
      FILTER_REGEX = Regexp.union(/\s*tree(\(|\z)/,
                                  /\s*flash(\(|\z)/,
                                  /\s*ids(\(|\z)/,
                                  /\s*labels(\(|\z)/,
                                  /\s*text(\(|\z)/,
                                  /\s*marks(\(|\z)/,
                                  /\s*verbose(\(|\z)/,
                                  /\s*quiet(\(|\z)/,
                                  /\s*clear(\(|\z)/,
                                  /\s*clear_clipboard(\(|\z)/,
                                  /\s*copy(\(|\z)/,
                                  /\s*start_test_server_in_background(\(|\z)/,
                                  /\s*exit(\(|\z)/)

      # @!visibility private
      def self.filter_commands(commands)
        commands.reject {|command| command =~ FILTER_REGEX}
      end

      # @!visibility private
      def self.readline_history
        require "readline"
        Readline::HISTORY.to_a
      end

      # @!visibility private
      def self.encode_utf8_or_raise(string)
        return "" if !string

        utf8 = string.force_encoding("UTF-8").chomp

        return utf8 if utf8.valid_encoding?

        encoded = utf8.encode("UTF-8", "UTF-8",
                              invalid: :replace, undef: :replace, replace: "")

        return encoded if encoded.valid_encoding?

        raise RuntimeError, %Q{
Could not force UTF-8 encoding on this string:

#{string}

Please file an issue with a stacktrace and the text of this error.

https://github.com/calabash/calabash-ios/issues
}
      end
    end
  end
end
