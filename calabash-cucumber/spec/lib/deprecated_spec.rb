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
  end
end
