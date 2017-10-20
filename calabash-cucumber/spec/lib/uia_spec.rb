
describe Calabash::Cucumber::UIA do

  let(:world) do
    Class.new do
      include Calabash::Cucumber::UIA
      include Calabash::Cucumber::HTTPHelpers
      include Calabash::Cucumber::WaitHelpers
      def to_s; "#<World RSPEC STUB>"; end
      def inspect; to_s; end

      # The dread Cucumber embed
      def embed(_, _, _); ; end
    end.new
  end

  context "Disabling UIA in the context of DeviceAgent" do
    let(:uia_path) do
      File.expand_path(File.join("lib", "calabash-cucumber", "uia.rb"))
    end

    let(:xcode) { RunLoop::Xcode.new }
    let(:automator) do
      Class.new(Calabash::Cucumber::Automator::Automator) do
        def to_s; "#<Automator RSPEC STUB>"; end
        def inspect; to_s; end
      end
    end

    context ".redefine_instance_methods_if_necessary" do
      it "does not rewrite on the XTC" do
        expect(Calabash::Cucumber::Environment).to receive(:xtc?).and_return(true)

        actual = Calabash::Cucumber::UIA.redefine_instance_methods_if_necessary(xcode, automator)
        expect(actual).to be_falsey
      end

      it "rewrites if Xcode >= 8" do
        expect(xcode).to receive(:version_gte_8?).and_return(true)
        expect(Calabash::Cucumber::UIA).to(
          receive(:redefine_instance_methods_to_raise).and_return(true)
        )

        actual = Calabash::Cucumber::UIA.redefine_instance_methods_if_necessary(xcode, automator)
        expect(actual).to be_truthy
      end

      context "Xcode < 8" do

        before do
          expect(xcode).to receive(:version_gte_8?).and_return(false)
        end

        it "does not rewrite if the automator arg is nil" do
          expect(Calabash::Cucumber::UIA).not_to receive(:redefine_instance_methods_to_raise)

          actual = Calabash::Cucumber::UIA.redefine_instance_methods_if_necessary(xcode, nil)
          expect(actual).to be_falsey
        end

        it "does not rewrite if the automator is not DeviceAgent" do
          expect(Calabash::Cucumber::UIA).not_to receive(:redefine_instance_methods_to_raise)
          expect(automator).to receive(:name).and_return(:instruments)

          actual = Calabash::Cucumber::UIA.redefine_instance_methods_if_necessary(xcode, automator)
          expect(actual).to be_falsey
        end

        it "rewrites if the automator is DeviceAgent" do
          expect(Calabash::Cucumber::UIA).to(
            receive(:redefine_instance_methods_to_raise).and_return(true)
          )
          expect(automator).to receive(:name).and_return(:device_agent)

          actual = Calabash::Cucumber::UIA.redefine_instance_methods_if_necessary(xcode, automator)
          expect(actual).to be_truthy
        end
      end
    end

    context ".redefine_instance_methods_to_raise" do
      let(:reason) { "Why did this raise" }

      it "rewrites all the UIA instance methods to raise" do
        methods = Calabash::Cucumber::UIA.instance_methods

        actual = Calabash::Cucumber::UIA.redefine_instance_methods_to_raise(reason)
        expect(actual).to be_truthy

        methods.each do |method_name|
          expect do
            world.send(method_name)
          end.to raise_error RuntimeError, /#{reason}/
        end
      end
    end

    after do
      load(uia_path)

      # Test that UIA was reloaded.
      expect(world.escape_uia_string("string")).to be == "string"
    end
  end
end
