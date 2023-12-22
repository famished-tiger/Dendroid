# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib\dendroid/syntax/terminal'
require_relative '../../../lib/dendroid/lexical/token_position'
require_relative '../../../lib/dendroid/lexical/literal'
require_relative '../../../lib/dendroid/parsing/terminal_node'

RSpec.describe Dendroid::Parsing::TerminalNode do
  let(:ex_source) { '+' }
  let(:ex_pos) { Dendroid::Lexical::TokenPosition.new(2, 5) }
  let(:ex_terminal) { Dendroid::Syntax::Terminal.new('PLUS') }
  let(:plus_token) { Dendroid::Lexical::Token.new(ex_source, ex_pos, ex_terminal) }
  let(:plus_node) { described_class.new(ex_terminal, plus_token, 3) }

  let(:int_source) { '2' }
  let(:int_symbol) { Dendroid::Syntax::Terminal.new('INTEGER') }
  let(:int_token)  { Dendroid::Lexical::Literal.new(int_source, ex_pos, int_symbol, 2) }
  let(:int_node) { described_class.new(int_symbol, int_token, 5) }

  context 'Initialization:' do
    it 'should be initialized with a symbol, terminal and a rank' do
      expect { described_class.new(ex_terminal, plus_token, 3) }.not_to raise_error
    end
  end # context

  context 'provided services:' do
    it 'renders a String representation of itself' do
      expect(plus_node.to_s).to eq('PLUS [3..4]')
    end

    it 'renders also the token value (if any)' do
      expect(int_node.to_s).to eq('INTEGER: 2 [5..6]')
    end
  end
end
