# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\syntax\terminal'
require_relative '..\..\..\lib\dendroid\syntax\non_terminal'
require_relative '..\..\..\lib\dendroid\syntax\symbol_seq'
require_relative '..\..\..\lib\dendroid\syntax\rule'

describe Dendroid::Syntax::Rule do
  let(:num_symb) { Dendroid::Syntax::Terminal.new('NUMBER') }
  let(:plus_symb) { Dendroid::Syntax::Terminal.new('PLUS') }
  let(:minus_symb) { Dendroid::Syntax::Terminal.new('MINUS') }
  let(:expr_symb) { Dendroid::Syntax::NonTerminal.new('expression') }
  let(:foo_symb) { Dendroid::Syntax::NonTerminal.new('foo') }
  let(:alt1) { Dendroid::Syntax::SymbolSeq.new([num_symb, plus_symb, num_symb]) }
  let(:alt2) { Dendroid::Syntax::SymbolSeq.new([num_symb, minus_symb, num_symb]) }
  let(:empty_body) { Dendroid::Syntax::SymbolSeq.new([]) }

  # Implements a choice rule:
  #   expression => NUMBER PLUS NUMBER
  #              |  NUMBER MINUS NUMBER
  #              |  epsilon
  subject { described_class.new(expr_symb, [alt1, alt2, empty_body]) }

  context 'Initialization:' do
    it 'is initialized with a head and alternatives' do
      expect { described_class.new(expr_symb, [alt1, alt2, empty_body]) }.not_to raise_error
    end

    it 'knows its head (aka lhs)' do
      expect(subject.head).to eq(expr_symb)
    end

    it 'knows its alternatives' do
      expect(subject.alternatives).to eq([alt1, alt2, empty_body])
    end

    it 'renders a String representation of itself' do
      expectation = 'expression => NUMBER PLUS NUMBER | NUMBER MINUS NUMBER | '
      expect(subject.to_s).to eq(expectation)
    end
  end # context

  context 'Provided services:' do
    it 'knows its terminal members' do
      expect(subject.terminals).to eq([num_symb, plus_symb, minus_symb])
    end

    it 'knows its non-terminal members' do
      expect(subject.nonterminals).to be_empty

      my_alt1 = Dendroid::Syntax::SymbolSeq.new([expr_symb, plus_symb, expr_symb])
      my_alt2 = Dendroid::Syntax::SymbolSeq.new([foo_symb, minus_symb, expr_symb])
      instance = described_class.new(foo_symb, [my_alt1, my_alt2])
      expect(instance.nonterminals).to eq([expr_symb, foo_symb])
    end
  end # context

  context 'Errors:' do
    context 'Errors:' do
      it 'fails when initialized with a terminal' do
        msg = "Terminal symbol 'NUMBER' may not be on left-side of a rule."
        expect { described_class.new(num_symb, []) }.to raise_error(StandardError, msg)
      end
    end

    it 'fails when initialized with one alternative only' do
      err = StandardError
      err_msg = 'The choice for `expression` must have at least one alternative.'
      expect { described_class.new(expr_symb, []) }.to raise_error(err, err_msg)
    end

    it 'fails in presence of duplicate rhs' do
      err = StandardError
      err_msg = 'Duplicate alternatives: expression => NUMBER PLUS NUMBER'
      expect { described_class.new(expr_symb, [alt1, alt2, alt1]) }.to raise_error(err, err_msg)
    end
  end # context
end # describe
