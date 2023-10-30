# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\syntax\terminal'
require_relative '..\..\..\lib\dendroid\syntax\non_terminal'
require_relative '..\..\..\lib\dendroid\syntax\symbol_seq'
require_relative '..\..\..\lib\dendroid\syntax\production'
require_relative '..\..\..\lib\dendroid\grm_analysis\dotted_item'

describe Dendroid::GrmAnalysis::DottedItem do
  let(:num_symb) { Dendroid::Syntax::Terminal.new('NUMBER') }
  let(:plus_symb) { Dendroid::Syntax::Terminal.new('PLUS') }
  let(:expr_symb) { Dendroid::Syntax::NonTerminal.new('expression') }
  let(:rhs) { Dendroid::Syntax::SymbolSeq.new([num_symb, plus_symb, num_symb]) }
  let(:empty_body) { Dendroid::Syntax::SymbolSeq.new([]) }
  let(:prod) { Dendroid::Syntax::Production.new(expr_symb, rhs) }
  let(:empty_prod) { Dendroid::Syntax::Production.new(expr_symb, empty_body) }

  # Implements a dotted item: expression => NUMBER . PLUS NUMBER
  subject { described_class.new(prod, 1) }

  context 'Initialization:' do
    it 'is initialized with a production and a dot position' do
      expect { described_class.new(prod, 1) }.not_to raise_error
    end

    it 'knows its related production' do
      expect(subject.rule).to eq(prod)
    end

    it 'knows its position' do
      expect(subject.position).to eq(1)
    end
  end # context

  context 'Provided services:' do
    it 'renders a String representation of itself' do
      expect(subject.to_s).to eq('expression => NUMBER . PLUS NUMBER')
    end

    it 'knows its state' do
      expect(described_class.new(prod, 0).state).to eq(:initial)
      expect(described_class.new(prod, 1).state).to eq(:partial)
      expect(described_class.new(prod, 3).state).to eq(:completed)

      # Case of an empty production
      expect(described_class.new(empty_prod, 0).state).to eq(:initial_and_completed)
    end

    it 'knows whether it is in the initial position' do
      expect(described_class.new(prod, 0)).to be_initial_pos
      expect(described_class.new(prod, 2)).not_to be_initial_pos
      expect(described_class.new(prod, 3)).not_to be_initial_pos

      # Case of an empty production
      expect(described_class.new(empty_prod, 0)).to be_initial_pos
    end

    it 'knows whether it is in the final position' do
      expect(described_class.new(prod, 0)).not_to be_final_pos
      expect(described_class.new(prod, 2)).not_to be_final_pos
      expect(described_class.new(prod, 3)).to be_final_pos
      expect(described_class.new(prod, 3)).to be_completed

      # Case of an empty production
      expect(described_class.new(empty_prod, 0)).to be_final_pos
    end

    it 'knows whether it is in an intermediate position' do
      expect(described_class.new(prod, 0)).not_to be_intermediate_pos
      expect(described_class.new(prod, 2)).to be_intermediate_pos
      expect(described_class.new(prod, 3)).not_to be_intermediate_pos

      # Case of an empty production
      expect(described_class.new(empty_prod, 0)).not_to be_intermediate_pos
    end

    it 'knows the symbol after the dot (if any)' do
      expect(described_class.new(prod, 0).next_symbol.name).to eq(:NUMBER)
      expect(described_class.new(prod, 1).next_symbol.name).to eq(:PLUS)
      expect(described_class.new(prod, 2).next_symbol.name).to eq(:NUMBER)
      expect(described_class.new(prod, 3).next_symbol).to be_nil

      # Case of an empty production
      expect(described_class.new(empty_prod, 0).next_symbol).to be_nil
    end

    it 'can compare a given symbol to the expected one' do
      expect(described_class.new(prod, 0)).to be_expecting(num_symb)
      expect(described_class.new(prod, 0)).not_to be_expecting(plus_symb)
      expect(described_class.new(prod, 1)).to be_expecting(plus_symb)
      expect(described_class.new(prod, 2)).to be_expecting(num_symb)
      expect(described_class.new(prod, 3)).not_to be_expecting(num_symb)
      expect(described_class.new(prod, 3)).not_to be_expecting(plus_symb)

      # Case of an empty production
      expect(described_class.new(empty_prod, 0)).not_to be_expecting(num_symb)
      expect(described_class.new(empty_prod, 0)).not_to be_expecting(plus_symb)
    end
  end # context
end # describe
