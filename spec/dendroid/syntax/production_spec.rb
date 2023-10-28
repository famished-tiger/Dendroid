# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\syntax\terminal'
require_relative '..\..\..\lib\dendroid\syntax\non_terminal'
require_relative '..\..\..\lib\dendroid\syntax\symbol_seq'
require_relative '..\..\..\lib\dendroid\syntax\production'

describe Dendroid::Syntax::Production do
  let(:num_symb) { Dendroid::Syntax::Terminal.new('NUMBER') }
  let(:plus_symb) { Dendroid::Syntax::Terminal.new('PLUS') }
  let(:expr_symb) { Dendroid::Syntax::NonTerminal.new('expression') }
  let(:foo_symb) { Dendroid::Syntax::NonTerminal.new('foo') }
  let(:rhs) { Dendroid::Syntax::SymbolSeq.new([num_symb, plus_symb, num_symb]) }
  let(:empty_body) { Dendroid::Syntax::SymbolSeq.new([]) }

  # Implements a production rule: expression => NUMBER PLUS NUMBER
  subject { described_class.new(expr_symb, rhs) }

  context 'Initialization:' do
    it 'is initialized with a head and a body' do
      expect { described_class.new(expr_symb, rhs) }.not_to raise_error
    end

    it 'knows its body (aka rhs)' do
      expect(subject.body).to eq(rhs)
    end

    it 'renders a String representation of itself' do
      expect(subject.to_s).to eq('expression => NUMBER PLUS NUMBER')
    end
  end # context

  context 'Provided services:' do
    it 'knows whether its body empty is empty or not' do
      expect(described_class.new(expr_symb, empty_body).empty?).to be_truthy
      expect(subject.empty?).to be_falsey
    end

    it 'knows its non-terminal members' do
      foo_rhs = Dendroid::Syntax::SymbolSeq.new([expr_symb, plus_symb, expr_symb])
      instance = described_class.new(foo_symb, foo_rhs)
      expect(instance.nonterminals).to eq([expr_symb])
    end

    it 'knows its terminal members' do
      expect(subject.terminals).to eq([num_symb, plus_symb])
    end

    # rubocop: disable Lint/BinaryOperatorWithIdenticalOperands
    it 'can compare with another production' do
      expect(subject == subject).to be_truthy

      same = described_class.new(expr_symb, rhs)
      expect(subject == same).to be_truthy

      # Different lhs, same rhs
      different_lhs = described_class.new(foo_symb, rhs)
      expect(subject == different_lhs).to be_falsey

      # Same lhs, different rhs
      different_rhs = described_class.new(expr_symb, empty_body)
      expect(subject == different_rhs).to be_falsey

      # Two productions with same lhs and empty bodies
      empty = described_class.new(expr_symb, empty_body)
      void = described_class.new(expr_symb, Dendroid::Syntax::SymbolSeq.new([]))
      expect(empty == void).to be_truthy

      # Two productions with distinct lhs and empty bodies
      empty = described_class.new(expr_symb, empty_body)
      void = described_class.new(foo_symb, Dendroid::Syntax::SymbolSeq.new([]))
      expect(empty == void).to be_falsey
    end
    # rubocop: enable Lint/BinaryOperatorWithIdenticalOperands
  end # context
end # describe
