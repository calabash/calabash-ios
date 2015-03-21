describe Calabash::Cucumber do
  describe  'deprecated APIs' do
    describe 'constants' do

      # We hack around self.const_missing to issue deprecation messages.
      # This test ensures we haven't broken self.cont_missing.
      it 'throws non-defined constants with NameError' do
        # noinspection RubyResolve
        expect{ Calabash::Cucumber::MISSING_CONSTANT }.to raise_error(NameError, 'uninitialized constant Calabash::Cucumber::MISSING_CONSTANT')
      end

      it 'FRAMEWORK_VERSION' do
        val = nil
        out = capture_stderr do
          # noinspection RubyResolve
          val = Calabash::Cucumber::FRAMEWORK_VERSION
        end
        expect(out.string).not_to be == nil
        expect(out.string).not_to be == ''
        expect(out.string =~ /FRAMEWORK_VERSION has been deprecated/).not_to be == nil
        expect(val).to be == nil
      end
    end

    it 'Device iphone_4in attribute' do
      simulator_data = Resources.shared.server_version :simulator
      endpoint = 'http://localhost:37265'
      device = Calabash::Cucumber::Device.new(endpoint, simulator_data)
      out = capture_stderr do
        device.iphone_4in
      end
      expect(out.string).not_to be == nil
      expect(out.string).not_to be == ''
      expect(out.string =~ /WARN: deprecated '0.13.1' - 'use 'iphone_4in\?' instead/).not_to be == nil
    end
  end
end
