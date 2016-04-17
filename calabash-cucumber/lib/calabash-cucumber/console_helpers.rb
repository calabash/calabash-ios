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

        query('*').each { |view|
          aid = view[kind.to_s]
          unless aid.nil? or aid.eql?('')
            cls = view['class']
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
        all_texts = query('*', :text)
        all_texts.each { |view|
          indexes << idx unless view.eql?('*****') or view.eql?('')
          idx = idx + 1
        }

        results = Array.new

        all_views = query('*')
        max_width = 0
        indexes.each { |index|
          view = all_views[index]
          cls = view['class']
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
        json_data['children'].each {|child| write_child(child)}
      end

      def write_child(data, indentation=0)
        render(data, indentation)
        data['children'].each do |child|
          write_child(child, indentation+1)
        end
      end

      def render(data, indentation)
        if visible?(data)
          type = data['type']

          str_type = if data['type'] == 'dom'
            "#{RunLoop::Color.cyan("[")}#{type}:#{RunLoop::Color.cyan("#{data['nodeName']}]")} "
          else
            RunLoop::Color.cyan("[#{type}] ")
          end

          str_id = data['id'] ? "[id:#{RunLoop::Color.blue(data['id'])}] " : ''
          str_label = data['label'] ? "[label:#{RunLoop::Color.green(data['label'])}] " : ''
          str_text = data['value'] ? "[text:#{RunLoop::Color.magenta(data['value'])}] " : ''
          output("#{str_type}#{str_id}#{str_label}#{str_text}", indentation)
          output("\n", indentation)
        end
      end

      def visible?(data)
        (data['visible'] == 1) || data['children'].map{|child| visible?(child)}.any?
      end

      def output(string, indentation)
        (indentation*2).times {print " "}
        print "#{string}"
      end
    end
  end
end
