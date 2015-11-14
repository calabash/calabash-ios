describe Calabash::DotDir do

  let(:home_dir) { "./tmp/dot-calaash-examples" }
  let(:dot_dir) { File.join(home_dir, ".calabash") }

  before do
    allow(RunLoop::Environment).to receive(:user_home_directory).and_return home_dir
    FileUtils.rm_rf(home_dir)
  end

  it ".directory" do
    path = Calabash::DotDir.directory

    expect(File.exist?(path)).to be_truthy
  end
end

