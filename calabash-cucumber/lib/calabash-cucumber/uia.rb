require 'edn'
module Calabash
  module Cucumber
    module UIA

      def send_uia_command(opts ={})
        run_loop = opts[:run_loop] || (@calabash_launcher && @calabash_launcher.active? && @calabash_launcher.run_loop)
        command = opts[:command]
        raise ArgumentError, 'please supply :run_loop or instance var @calabash_launcher' unless run_loop
        raise ArgumentError, 'please supply :command' unless command
        RunLoop.send_command(run_loop, opts[:command])
      end

      def uia_query(*queryparts)
        #TODO escape ' in query
        uia_handle_command(:query, queryparts)
      end

      def uia_tap(*queryparts)
        #TODO escape ' in query
        uia_handle_command(:tap, queryparts)
      end

      def uia_handle_command(cmd, query)
        command = %Q[uia.#{cmd}('#{query.to_edn}')]
        if ENV['DEBUG'] == '1'
          puts "Sending UIA command"
          puts command
        end
        s=send_uia_command :command => command
        if ENV['DEBUG'] == '1'
          puts "Result"
          p s
        end
        if s['status'] == 'success'
          s['value']
        else
          raise s
        end
      end


    end
  end
end