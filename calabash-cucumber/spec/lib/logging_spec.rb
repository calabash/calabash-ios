require 'stringio'

describe 'calabash logging' do

  include Calabash::Cucumber::Logging

  it 'should output deprecated messages' do
    version = '0.9.169'
    dep_msg = 'this is a deprecation message'
    out = capture_stderr do
      _deprecated(version, dep_msg, :warn)
    end
    tokens = out.string.split("\n")
    expect("#{tokens[0]}\n#{tokens[1]}").to be == "\e[34m\nWARN: deprecated '#{version}' - #{dep_msg}"
    expect(tokens.count).to be > 5
    expect(tokens.count).to be < 9
  end
end

describe Calabash::Cucumber do

  describe "file logging" do
    let(:now) { Time.now }

    it ".timestamp" do
      expected = now.strftime("%Y-%m-%d_%H-%M-%S")
      expect(Time).to receive(:now).and_return(now)

      actual = Calabash::Cucumber.send(:timestamp)
      expect(actual).to be == expected
    end

    describe "logs directory and calabash.log" do
      let(:tmp_dir) { File.expand_path("tmp") }
      let(:log_file) { File.join(tmp_dir, "logs", "calabash.log") }

      before do
        FileUtils.rm_rf(tmp_dir)
        allow(Calabash::Cucumber::DotDir).to receive(:directory).and_return(tmp_dir)
      end

      it ".logs_directory" do
        actual = Calabash::Cucumber.send(:logs_directory)
        expect(actual).to be == File.join(tmp_dir, "logs")
        expect(File.exist?(actual)).to be_truthy
      end

      describe ".calabash_log_file" do
        it "creates the log file if it does not exist" do
          expect(FileUtils).to receive(:touch).and_call_original

          actual = Calabash::Cucumber.send(:calabash_log_file)
          expect(actual).to be == log_file
          expect(File.exist?(actual)).to be_truthy
        end

        it "returns the log file if it does exist" do
          FileUtils.mkdir_p(File.join(tmp_dir, "logs"))
          FileUtils.touch(log_file)
          expect(FileUtils).not_to receive(:touch).with(log_file)

          actual = Calabash::Cucumber.send(:calabash_log_file)
          expect(actual).to be == log_file
          expect(File.exist?(actual)).to be_truthy
        end
      end

      describe ".log_to_file" do

        before do
          allow(Calabash::Cucumber).to receive(:timestamp).and_return("stamp")
        end

        it "appends message to log file" do
          Calabash::Cucumber.log_to_file("Pushing mid")
          lines = File.read(log_file).force_encoding("utf-8").split($-0)

          expect(lines.count).to be == 1
          expect(lines[0]).to be == "stamp Pushing mid"

          Calabash::Cucumber.log_to_file("Get over here!")
          lines = File.read(log_file).force_encoding("utf-8").split($-0)

          expect(lines.count).to be == 2
          expect(lines[0]).to be == "stamp Pushing mid"
          expect(lines[1]).to be == "stamp Get over here!"
        end

        it "splits multiline messages into lines" do
          lines = [
            "Pushing mid",
            "Get over here!"
          ].join($-0)

          Calabash::Cucumber.log_to_file(lines)
          lines = File.read(log_file).force_encoding("utf-8").split($-0)

          expect(lines.count).to be == 2
          expect(lines[0]).to be == "stamp Pushing mid"
          expect(lines[1]).to be == "stamp Get over here!"
        end

        it "handles errors by logging when debugging" do
          allow(RunLoop::Environment).to receive(:debug?).and_return true
          expect(File).to receive(:open).and_raise StandardError, "Did not get the last hit"

          actual = capture_stdout do
            Calabash::Cucumber.log_to_file("message")
          end.string.gsub(/\e\[(\d+)m/, "")

          expected = "DEBUG: Could not write:\n\nmessage\n\nto calabash.log because:\n\nDid not get the last hit\n\n"
          expect(actual).to be == expected
        end

        it "handles errors by ignoring them when not debugging" do
          allow(RunLoop::Environment).to receive(:debug?).and_return false
          expect(File).to receive(:open).and_raise StandardError, "Did not get the last hit"

          actual = capture_stdout do
            Calabash::Cucumber.log_to_file("message")
          end.string.gsub(/\e\[(\d+)m/, "")

          expect(actual).to be == ""
        end
      end
    end
  end
end

