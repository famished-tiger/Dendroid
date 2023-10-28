# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\syntax\terminal'
require_relative '..\..\..\lib\dendroid\syntax\non_terminal'
require_relative '..\..\..\lib\dendroid\syntax\symbol_seq'

describe Dendroid::Syntax::SymbolSeq do
  let(:num_symb) { Dendroid::Syntax::Terminal.new('NUMBER') }
  let(:plus_symb) { Dendroid::Syntax::Terminal.new('PLUS') }

  subject { described_class.new([num_symb, plus_symb, num_symb]) }

  context 'Initialization:' do
    it 'is initialized with an empty array' do
      expect { described_class.new([]) }.not_to raise_error
    end

    it 'is initialized with an array of GrmSymbols' do
      expect { described_class.new([num_symb, plus_symb, num_symb]) }.not_to raise_error
    end

    it 'knows its members' do
      expect(subject.members).to eq([num_symb, plus_symb, num_symb])
    end
  end # context

  context 'Provided services:' do
    let(:expr_symb) { Dendroid::Syntax::NonTerminal.new('PLUS') }

    it 'knows whether its body empty is empty or not' do
      expect(described_class.new([]).empty?).to be_truthy
      expect(subject.empty?).to be_falsey
    end

    it 'renders a String representation of itself' do
      expect(subject.to_s).to eq('NUMBER PLUS NUMBER')
    end

    it 'knows its non-terminal members' do
      instance = described_class.new([expr_symb, plus_symb, expr_symb])
      expect(instance.nonterminals).to eq([expr_symb, expr_symb])
    end

    it 'knows its terminal members' do
      expect(subject.terminals).to eq([num_symb, plus_symb, num_symb])
    end

    # rubocop: disable Lint/BinaryOperatorWithIdenticalOperands
    it 'can compare with another symbol sequence' do
      expect(subject == subject).to be_truthy
      same = described_class.new([num_symb, plus_symb, num_symb])
      expect(subject == same).to be_truthy
      different = described_class.new([num_symb, plus_symb, plus_symb])
      expect(subject == different).to be_falsey

      # Comparing two empty sequences
      empty = described_class.new([])
      void = described_class.new([])
      expect(empty == void).to be_truthy
    end
    # rubocop: enable Lint/BinaryOperatorWithIdenticalOperands

    it 'knows whether it is productive' do
      # Case: all members are productive
      expect(subject.productive?).to be_truthy

      # Case: at least one member is non-productive (expr_symb.productive is nil)
      instance = described_class.new([expr_symb, plus_symb, num_symb])
      expect(instance.productive?).to be_falsey
    end
  end # context
end # describe
