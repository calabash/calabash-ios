describe Calabash::Cucumber::QueryHelpers do

  let(:single_quote)         { "karl's problem" }
  let(:single_quote_escaped) { "karl\\'s problem" }
  let(:double_quote)         { "karl's \"problem\""  }
  let(:double_quote_escaped) { "karl\\'s \"problem\""  }
  let(:backslash)            { "karl's \\ problem" }
  let(:backslash_escaped)    { "karl\\'s \\\\ problem" }
  let(:escaper)    { Object.new.extend(Calabash::Cucumber::QueryHelpers) }

  describe '#escape_string' do
    it 'escapes single_quotes (\')' do
      expect(escaper.escape_string(single_quote)).to be == single_quote_escaped
    end
    it 'leaves double quotes unescaped' do
      expect(escaper.escape_string(double_quote)).to be == double_quote_escaped
    end
    it 'escapes backslashes(\\)' do
      expect(escaper.escape_string(backslash)).to be == backslash_escaped
    end
  end

end
