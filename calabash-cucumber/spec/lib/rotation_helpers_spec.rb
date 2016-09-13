describe Calabash::Cucumber::RotationHelpers do

  let(:helper) do
    Class.new do
      include Calabash::Cucumber::RotationHelpers
      include Calabash::Cucumber::EnvironmentHelpers
    end.new
  end

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
  end

  context "#orientation_for_key" do
    it "returns the value of the key in DEVICE_ORIENTATION" do
      stub_const("Calabash::Cucumber::RotationHelpers::DEVICE_ORIENTATION",
                 {:key => :value})

      expect(helper.orientation_for_key(:key)).to be == :value
    end
  end

  describe '#orientation_key' do
    describe 'rotate :left' do
      it 'returns :landscape_left when home button is :down' do
        expect(helper.send(:orientation_key, :left, :down)).to be == :landscape_left
      end

      it 'returns :upside_down when home button is :right' do
        expect(helper.send(:orientation_key, :left, :right)).to be == :upside_down
      end

      it 'returns :portrait with home button is :left' do
        expect(helper.send(:orientation_key, :left, :left)).to be == :portrait
      end

      it 'returns :landscape_right when the home button is :up' do
        expect(helper.send(:orientation_key, :left, :up)).to be == :landscape_right
      end
    end

    describe 'rotate :right' do
      it 'returns :landscape_right when home button is :down' do
        expect(helper.send(:orientation_key, :right, :down)).to be == :landscape_right
      end

      it 'returns :portrait when home button is :right' do
        expect(helper.send(:orientation_key, :right, :right)).to be == :portrait
      end

      it 'returns :upside_down when home button is :left' do
        expect(helper.send(:orientation_key, :right, :left)).to be == :upside_down
      end

      it 'returns :landscape_left when home button is :up' do
        expect(helper.send(:orientation_key, :right, :up)).to be == :landscape_left
      end
    end
  end

  describe '#expect_valid_rotate_home_to_arg' do
    it 'raises error when arg is invalid' do
      expect do
        helper.send(:expect_valid_rotate_home_to_arg, :invalid)
      end.to raise_error ArgumentError, /Expected/
    end

    describe 'valid arguments' do
      it 'top' do
        expect(helper.send(:expect_valid_rotate_home_to_arg, 'top')).to be == :up
      end

      it ':top' do
        expect(helper.send(:expect_valid_rotate_home_to_arg, :top)).to be == :up
      end

      it 'bottom' do
        expect(helper.send(:expect_valid_rotate_home_to_arg, 'bottom')).to be == :down
      end

      it ':bottom' do
        expect(helper.send(:expect_valid_rotate_home_to_arg, :bottom)).to be == :down
      end
    end
  end
end
