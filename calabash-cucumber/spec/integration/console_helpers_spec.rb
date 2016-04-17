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
    dir = File.expand_path(File.dirname(__FILE__))
    path = File.expand_path(File.join(dir, "..", "..", "scripts", ".irbrc"))

    if !File.exist?(path)
      raise path
    end
    path
  end

  it "ids, labels, text, marks, and tree" do
    env = {"CALABASH_IRBRC" => dot_irbrc}
    out, err = nil
    Open3.popen3(env, "bundle", "exec", "calabash-ios", "console") do |stdin, stdout, stderr, _|
      stdin.puts "start_test_server_in_background(#{launch_options})"
      stdin.puts "ids"
      stdin.puts "labels"
      stdin.puts "text"
      stdin.puts "marks"
      stdin.puts "tree"
      stdin.close
      out = stdout.read.strip
      err = stderr.read.strip
    end

    puts out
    puts err
    expect(out[/Error/,0]).to be == nil

    out_no_color = out.gsub(/\e\[(\d+)m/, "")

    # message of the day
    expect(out_no_color[/Calabash says,/, 0]).to be_truthy

    expect(err).to be == ""
  end
end
