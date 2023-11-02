# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/dendroid/syntax/terminal'
require_relative '../../../lib/dendroid/syntax/non_terminal'
require_relative '../../../lib/dendroid/syntax/symbol_seq'
require_relative '../../../lib/dendroid/syntax/production'
require_relative '../../../lib/dendroid/grm_analysis/dotted_item'
require_relative '../../../lib/dendroid/recognizer/e_item'
require_relative '../../../lib/dendroid/recognizer/item_set'

describe Dendroid::Recognizer::ItemSet do
  let(:num_symb) { Dendroid::Syntax::Terminal.new('NUMBER') }
  let(:plus_symb) { Dendroid::Syntax::Terminal.new('PLUS') }
  let(:expr_symb) { Dendroid::Syntax::NonTerminal.new('expression') }
  let(:rhs) { Dendroid::Syntax::SymbolSeq.new([num_symb, plus_symb, num_symb]) }
  let(:empty_body) { Dendroid::Syntax::SymbolSeq.new([]) }
  let(:prod) { Dendroid::Syntax::Production.new(expr_symb, rhs) }
  let(:empty_prod) { Dendroid::Syntax::Production.new(expr_symb, empty_body) }
  let(:sample_dotted) { Dendroid::GrmAnalysis::DottedItem.new(prod, 1) }
  let(:sample_origin) { 3 }
  let(:other_dotted) { Dendroid::GrmAnalysis::DottedItem.new(empty_prod, 0) }
  let(:first_element) { Dendroid::Recognizer::EItem.new(sample_dotted, sample_origin) }
  let(:second_element) { Dendroid::Recognizer::EItem.new(other_dotted, 5) }

  subject { described_class.new }

  context 'Initialization:' do
    it 'is initialized without argument' do
      expect { described_class.new }.not_to raise_error
    end

    it 'is empty at creation' do
      expect(subject).to be_empty
    end
  end # context

  context 'Provided services:' do
    it 'adds a new element' do
      subject.add_item(first_element)
      expect(subject.size).to eq(1)

      # Trying a second time, doesn't change the set
      subject.add_item(first_element)
      expect(subject.size).to eq(1)

      subject.add_item(second_element)
      expect(subject.size).to eq(2)
    end

    it 'can render a String representation of itself' do
      subject.add_item(first_element)
      subject.add_item(second_element)

      expectations = [
        'expression => NUMBER . PLUS NUMBER @ 3',
        'expression => . @ 5'
      ].join("\n")

      expect(subject.to_s).to eq(expectations)
    end
  end # context
end # describe
