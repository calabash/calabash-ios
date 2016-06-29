
describe Calabash::Cucumber::Abstract do

  let(:object) do
    Class.new do
      include Calabash::Cucumber::Abstract

      def an_abstract_method
        abstract_method!
      end
    end.new
  end

  it "#abstract_method" do
    expect do
      object.an_abstract_method
    end.to raise_error Calabash::Cucumber::Abstract::AbstractMethodError, /an_abstract_method/
  end
end

