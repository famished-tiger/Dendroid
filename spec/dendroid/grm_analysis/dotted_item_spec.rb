# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\syntax\terminal'
require_relative '..\..\..\lib\dendroid\syntax\non_terminal'
require_relative '..\..\..\lib\dendroid\syntax\symbol_seq'
require_relative '..\..\..\lib\dendroid\syntax\rule'
require_relative '..\..\..\lib\dendroid\grm_analysis\dotted_item'

describe Dendroid::GrmAnalysis::DottedItem do
  let(:num_symb) { Dendroid::Syntax::Terminal.new('NUMBER') }
  let(:plus_symb) { Dendroid::Syntax::Terminal.new('PLUS') }
  let(:minus_symb) { Dendroid::Syntax::Terminal.new('MINUS') }
  let(:expr_symb) { Dendroid::Syntax::NonTerminal.new('expression') }
  let(:rhs1) { Dendroid::Syntax::SymbolSeq.new([num_symb, plus_symb, num_symb]) }
  let(:rhs2) { Dendroid::Syntax::SymbolSeq.new([num_symb, minus_symb, num_symb]) }
  let(:empty_body) { Dendroid::Syntax::SymbolSeq.new([]) }
  let(:choice) { Dendroid::Syntax::Rule.new(expr_symb, [rhs1, rhs2, empty_body]) }

  # Implements a dotted item: expression => NUMBER . MINUS NUMBER
  subject { described_class.new(choice, 1, 1) }

  context 'Initialization:' do
    it 'is initialized with a production and a dot position' do
      expect { described_class.new(choice, 1, 1) }.not_to raise_error
    end

    it 'knows its related production' do
      expect(subject.rule).to eq(choice)
    end

    it 'knows its position' do
      expect(subject.position).to eq(1)
    end
  end # context

  context 'Provided services:' do
    it 'renders a String representation of itself' do
      expect(subject.to_s).to eq('expression => NUMBER . MINUS NUMBER')
    end

    it 'knows its state' do
      expect(described_class.new(choice, 0, 1).state).to eq(:initial)
      expect(described_class.new(choice, 1, 1).state).to eq(:partial)
      expect(described_class.new(choice, 3, 1).state).to eq(:completed)

      # Case of an empty alternative
      expect(described_class.new(choice, 0, 2).state).to eq(:initial_and_completed)
    end

    it 'knows whether it is in the initial position' do
      expect(described_class.new(choice, 0, 0)).to be_initial_pos
      expect(described_class.new(choice, 2, 0)).not_to be_initial_pos
      expect(described_class.new(choice, 3, 0)).not_to be_initial_pos

      # Case of an empty alternative
      expect(described_class.new(choice, 0, 2)).to be_initial_pos
    end

    it 'knows whether it is in the final position' do
      expect(described_class.new(choice, 0, 1)).not_to be_final_pos
      expect(described_class.new(choice, 2, 1)).not_to be_final_pos
      expect(described_class.new(choice, 3, 1)).to be_final_pos
      expect(described_class.new(choice, 3, 1)).to be_completed

      # Case of an empty alternative
      expect(described_class.new(choice, 0, 2)).to be_final_pos
    end

    it 'knows whether it is in an intermediate position' do
      expect(described_class.new(choice, 0, 0)).not_to be_intermediate_pos
      expect(described_class.new(choice, 2, 0)).to be_intermediate_pos
      expect(described_class.new(choice, 3, 0)).not_to be_intermediate_pos

      # Case of an empty alternative
      expect(described_class.new(choice, 0, 2)).not_to be_intermediate_pos
    end

    it 'knows the symbol after the dot (if any)' do
      expect(described_class.new(choice, 0, 1).next_symbol.name).to eq(:NUMBER)
      expect(described_class.new(choice, 1, 1).next_symbol.name).to eq(:MINUS)
      expect(described_class.new(choice, 2, 1).next_symbol.name).to eq(:NUMBER)
      expect(described_class.new(choice, 3, 1).next_symbol).to be_nil

      # Case of an empty alternative
      expect(described_class.new(choice, 0, 2).next_symbol).to be_nil
    end

    it 'knows the symbol before the dot (if any)' do
      expect(described_class.new(choice, 0, 1).prev_symbol).to be_nil
      expect(described_class.new(choice, 1, 1).prev_symbol.name).to eq(:NUMBER)
      expect(described_class.new(choice, 2, 1).prev_symbol.name).to eq(:MINUS)
      expect(described_class.new(choice, 3, 1).prev_symbol.name).to eq(:NUMBER)

      # Case of an empty alternative
      expect(described_class.new(choice, 0, 1).prev_symbol).to be_nil
    end

    it 'can compare a given symbol to the one expected' do
      expect(described_class.new(choice, 0, 1)).to be_expecting(num_symb)
      expect(described_class.new(choice, 0, 1)).not_to be_expecting(plus_symb)
      expect(described_class.new(choice, 1, 0)).to be_expecting(plus_symb)
      expect(described_class.new(choice, 1, 1)).to be_expecting(minus_symb)
      expect(described_class.new(choice, 2, 0)).to be_expecting(num_symb)
      expect(described_class.new(choice, 3, 1)).not_to be_expecting(num_symb)
      expect(described_class.new(choice, 3, 1)).not_to be_expecting(plus_symb)

      # Case of an empty alternative
      expect(described_class.new(choice, 0, 2)).not_to be_expecting(num_symb)
      expect(described_class.new(choice, 0, 2)).not_to be_expecting(plus_symb)
    end
  end # context
end # describe
