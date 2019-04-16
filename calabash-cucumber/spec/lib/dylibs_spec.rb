
describe Calabash::Cucumber::Dylibs do

  before do
    path = File.expand_path(File.join("tmp", "dylib-tests", "dylibs"))
    FileUtils.rm_rf(path)
    FileUtils.mkdir_p(path)

    FileUtils.touch(File.join(path, "libCalabashSim.dylib"))
    FileUtils.touch(File.join(path, "libCalabashARM.dylib"))

    expect(Calabash::Cucumber::Dylibs).to receive(:dylib_dir).and_return(path)
  end


  it "returns path to sim dylib" do
    path = Calabash::Cucumber::Dylibs.path_to_sim_dylib
    expect(File.exist?(path)).to be == true
  end

  it "returns path to device dylib" do
    path = Calabash::Cucumber::Dylibs.path_to_device_dylib
    expect(File.exist?(path)).to be == true
  end
end

