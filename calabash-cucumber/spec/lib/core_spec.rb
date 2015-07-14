describe Calabash::Cucumber::Core do

  let(:actions) do
    Class.new do
      def swipe(dir, options); :success; end
    end.new
  end

  let(:launcher) do
    Class.new do
      def actions; ; end
    end.new
  end

  let(:world) do
    Class.new do
      include Calabash::Cucumber::Core
    end.new
  end

  describe '#scroll' do
    describe 'handling direction argument' do
      describe 'raises error if invalid' do
        it 'keywords' do
          expect do
            world.scroll("query", :sideways)
          end.to raise_error ArgumentError
        end

        it 'strings' do
          expect do
            world.scroll("query", 'diagonal')
          end.to raise_error ArgumentError
        end
      end

      describe 'valid' do
        before do
          expect(world).to receive(:map).twice.and_return [true]
          expect(world).to receive(:assert_map_results).twice.and_return true
        end

        it 'up' do
          expect(world.scroll('', 'up')).to be_truthy
          expect(world.scroll('', :up)).to be_truthy
        end

        it 'down' do
          expect(world.scroll('', 'down')).to be_truthy
          expect(world.scroll('', :down)).to be_truthy
        end

        it 'left' do
          expect(world.scroll('', 'left')).to be_truthy
          expect(world.scroll('', :left)).to be_truthy
        end

        it 'right' do
          expect(world.scroll('', 'right')).to be_truthy
          expect(world.scroll('', :right)).to be_truthy
        end
      end
    end
  end

  describe '#swipe' do
    describe 'handling :force options' do

      describe 'valid options' do

        before do
          expect(world).to receive(:uia_available?).and_return true
          expect(world).to receive(:launcher).and_return launcher
          expect(launcher).to receive(:actions).and_return actions
          expect(actions).to receive(:swipe).and_return :success
        end

        it ':light' do
          expect(world.swipe(:left, {:force => :light})).to be == :success
        end

        it ':normal' do
          expect(world.swipe(:left, {:force => :light})).to be == :success
        end

        it ':strong' do
          expect(world.swipe(:left, {:force => :light})).to be == :success
        end
      end

      it 'raises error if unknown :force is passed' do
        expect(world).to receive(:uia_available?).and_return true
        expect {
          world.swipe(:left, {:force => :unknown})
        }.to raise_error ArgumentError
      end
    end

    describe 'handling options' do

      before do
        expect(world).to receive(:uia_available?).and_return false
        expect(world).to receive(:status_bar_orientation).and_return :down
        expect(world).to receive(:launcher).and_return launcher
        expect(launcher).to receive(:actions).and_return actions
      end

      describe 'uia is not available' do
        it 'adds :status_bar_orientation' do
          options = {}
          merged = {:status_bar_orientation => :down}
          expect(actions).to receive(:swipe).with(:left, merged).and_return :success

          expect(world.swipe(:left, options)).to be == :success
        end

        # I don't understand why the :status_bar_orientation value is overwritten.
        it 'does overwrites :status_bar_orientation' do
          options = {:status_bar_orientation => :left}
          merged = {:status_bar_orientation => :down}

          expect(actions).to receive(:swipe).with(:left, merged).and_return :success

          expect(world.swipe(:left, options)).to be == :success
        end
      end
    end
  end
end
