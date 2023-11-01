# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/dendroid/syntax/terminal'
require_relative '../../../lib/dendroid/syntax/non_terminal'
require_relative '../../../lib/dendroid/syntax/symbol_seq'
require_relative '../../../lib/dendroid/syntax/production'
require_relative '../../../lib/dendroid/grm_analysis/production_items'

describe Dendroid::GrmAnalysis::ProductionItems do
  let(:num_symb) { Dendroid::Syntax::Terminal.new('NUMBER') }
  let(:plus_symb) { Dendroid::Syntax::Terminal.new('PLUS') }
  let(:expr_symb) { Dendroid::Syntax::NonTerminal.new('expression') }
  let(:rhs) { Dendroid::Syntax::SymbolSeq.new([num_symb, plus_symb, num_symb]) }
  let(:empty_body) { Dendroid::Syntax::SymbolSeq.new([]) }
  let(:prod) { Dendroid::Syntax::Production.new(expr_symb, rhs) }
  let(:empty_prod) do
    e = Dendroid::Syntax::Production.new(expr_symb, empty_body)
    e.extend(Dendroid::GrmAnalysis::ProductionItems)
    e.build_items
    e
  end

  subject do
    prod.extend(Dendroid::GrmAnalysis::ProductionItems)
    prod.build_items
    prod
  end

  context 'Methods from mix-in' do
    it 'builds items for given non-empty production' do
      expect(subject.items.size).to eq(subject.body.size + 1)
      subject.items.each_with_index do |item, index|
        expect(item.rule).to eq(subject)
        expect(item.position).to eq(index)
      end
    end

    it 'builds the item for given empty production' do
      expect(empty_prod.items.size).to eq(1)
      expect(empty_prod.items[0].rule).to eq(empty_prod)
      expect(empty_prod.items[0].position).to eq(0)
    end

    it 'returns the first (predicted) item of the production' do
      expect(subject.predicted_items).to eq([subject.items.first])
      expect(empty_prod.predicted_items).to eq([empty_prod.items.first])
    end

    it 'returns the last (reduce) item of the production' do
      expect(subject.reduce_items).to eq([subject.items.last])
      expect(empty_prod.reduce_items).to eq([empty_prod.items.first])
    end

    # rubocop: disable Style/EachForSimpleLoop
    it 'returns the consecutive item to a given one' do
      (0..2).each do |pos|
        curr_item = subject.items[pos]
        next_one = subject.next_item(curr_item)
        expect(next_one).to eq(subject.items[pos + 1])
      end
      expect(subject.next_item(subject.items[-1])).to be_nil

      expect(empty_prod.next_item(empty_prod.items[-1])).to be_nil
    end
    # rubocop: enable Style/EachForSimpleLoop
  end # context
end # describe
