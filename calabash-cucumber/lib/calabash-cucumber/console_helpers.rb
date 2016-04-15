require 'calabash-cucumber/color'
module Calabash
  module Cucumber

    # A collection of methods that help you use console.
    module ConsoleHelpers
      include Calabash::Color
      
      def tree
        dump_json_data(JSON.parse(http({:method => :get, :path => 'dump'})))
        true
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
                       "#{Color.yellow("[")}#{type}:#{Color.yellow("#{data['nodeName']}]")} "
                     else
                       Color.yellow("[#{type}] ")
                     end

          str_id = data['id'] ? "[id:#{Color.blue(data['id'])}] " : ''
          str_label = data['label'] ? "[label:#{Color.green(data['label'])}] " : ''
          str_text = data['value'] ? "[text:#{Color.magenta(data['value'])}] " : ''
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
