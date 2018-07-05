if !Luffa::Environment.ci?
  describe "Calabash::Cucumber::ConsoleHelpers" do

    let(:launcher) { Calabash::Cucumber::Launcher.new }
    let(:other_launcher) { Calabash::Cucumber::Launcher.new }

    let(:launch_options) {
      {
        :app => Resources.shared.app_bundle_path(:cal_smoke_app),
        :device_target => "simulator",
        :no_stop => true,
        :launch_retries => Luffa::Retry.instance.launch_retries
      }
    }

    let(:dot_irbrc) do
      path = File.expand_path(File.join("scripts", ".irbrc"))

      if !File.exist?(path)
        raise path
      end
      path
    end

    it "calabash-ios console" do

      ENV["CALABASH_IRBRC"] = dot_irbrc
      env = {"CALABASH_IRBRC" => dot_irbrc}
      out, err = nil
      Open3.popen3(env, "bundle", "exec", "calabash-ios", "console") do |stdin, stdout, stderr, _|
        stdin.puts "start_test_server_in_background(#{launch_options})"
        stdin.puts "ids"
        stdin.puts "labels"
        stdin.puts %Q[query("view marked:'switch'")]
        stdin.puts "text"
        stdin.puts "marks"
        stdin.puts "tree"
        stdin.puts %Q[touch("view marked:'switch'")]
        stdin.puts "copy"
        stdin.puts "clear_clipboard"
        # Don't call because it messes with debugging output
        # stdin.puts "clear"
        stdin.close
        out = stdout.read.strip
        err = stderr.read.strip
      end

      puts out
      puts err
      expect(out[/Error/,0]).to be == nil
      expect(err).to be == ""

      out_no_color = out.gsub(/\e\[(\d+)m/, "")

      # message of the day
      expect(out_no_color[/Calabash says,/, 0]).to be_truthy

      # clip board does not seem to be available in subshell
      # copy-n-paste
      # expected = "query(\"view marked:'switch'\")\ntouch(\"view marked:'switch'\")"
      # expect(out_no_color[/#{expected}/,0]).to be_truthy
    end
  end
end
