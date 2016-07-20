
describe Calabash::Cucumber::LogTailer do
  context ".tail_in_terminal" do
    let(:path) { "path/to/log.txt" }
    it "opens a Terminal window and tails file passed in argument" do
      expect(File).to receive(:exist?).with(path).and_return(true)
      expect(Calabash::Cucumber::LogTailer).to receive(:run_command).and_return(true)

      expect(Calabash::Cucumber::LogTailer.tail_in_terminal(path)).to be_truthy
    end

    it "raises an error if the file does not exist" do
      expect(File).to receive(:exist?).with(path).and_return(false)

      expect do
        Calabash::Cucumber::LogTailer.tail_in_terminal(path)
      end.to raise_error RuntimeError, /Cannot tail a file that does not exist/
    end

    it "raises an error if there is a problem opening the Terminal window" do
      expect(File).to receive(:exist?).with(path).and_return(true)
      expect(Calabash::Cucumber::LogTailer).to receive(:run_command).and_return(false)

      expect do
        Calabash::Cucumber::LogTailer.tail_in_terminal(path)
      end.to raise_error RuntimeError, /Could not tail file/
    end
  end
end
