# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/dendroid/syntax/terminal'
require_relative '../../../lib/dendroid/syntax/non_terminal'
require_relative '../../../lib/dendroid/syntax/symbol_seq'
require_relative '../../../lib/dendroid/syntax/production'
require_relative '../../../lib/dendroid/grm_analysis/dotted_item'
require_relative '../../../lib/dendroid/recognizer/e_item'

describe Dendroid::Recognizer::EItem do
  let(:num_symb) { Dendroid::Syntax::Terminal.new('NUMBER') }
  let(:plus_symb) { Dendroid::Syntax::Terminal.new('PLUS') }
  let(:expr_symb) { Dendroid::Syntax::NonTerminal.new('expression') }
  let(:rhs) { Dendroid::Syntax::SymbolSeq.new([num_symb, plus_symb, num_symb]) }
  let(:empty_body) { Dendroid::Syntax::SymbolSeq.new([]) }
  let(:prod) { Dendroid::Syntax::Production.new(expr_symb, rhs) }
  let(:empty_prod) { Dendroid::Syntax::Production.new(expr_symb, empty_body) }
  let(:sample_dotted) { Dendroid::GrmAnalysis::DottedItem.new(prod, 1) }
  let(:other_dotted) { Dendroid::GrmAnalysis::DottedItem.new(empty_prod, 0) }
  let(:sample_origin) { 3 }

  subject { described_class.new(sample_dotted, sample_origin) }

  context 'Initialization:' do
    it 'is initialized with a dotted item and an origin position' do
      expect { described_class.new(sample_dotted, sample_origin) }.not_to raise_error
    end

    it 'knows its related dotted item' do
      expect(subject.dotted_item).to eq(sample_dotted)
    end

    it 'knows its origin value' do
      expect(subject.origin).to eq(sample_origin)
    end
  end # context

  context 'Provided service:' do
    it 'knows the lhs of related production' do
      expect(subject.lhs).to eq(expr_symb)
    end # context

    # rubocop: disable Lint/BinaryOperatorWithIdenticalOperands

    it 'can compare with another EItem' do
      expect(subject == subject).to be_truthy
      expect(subject == described_class.new(sample_dotted, sample_origin)).to be_truthy
      expect(subject == described_class.new(sample_dotted, 2)).to be_falsey
      expect(subject == described_class.new(other_dotted, sample_origin)).to be_falsey
    end

    # rubocop: enable Lint/BinaryOperatorWithIdenticalOperands

    it 'can renders a String representation of itself' do
      expect(subject.to_s).to eq("#{sample_dotted} @ #{sample_origin}")
    end
  end # context
end # describe
