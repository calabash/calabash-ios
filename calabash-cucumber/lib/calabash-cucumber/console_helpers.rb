module Calabash
  module Cucumber

    # A collection of methods that help you use console.
    module ConsoleHelpers

      # List the visible element ids.
      def ids
        accessibility_marks(:id)
      end

      # List the visible element labels.
      def labels
        accessibility_marks(:label)
      end

      # List the visible element texts.
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
    end
  end
end
