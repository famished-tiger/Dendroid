# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\syntax\terminal'
require_relative '..\..\..\lib\dendroid\syntax\non_terminal'
require_relative '..\..\..\lib\dendroid\syntax\symbol_seq'
require_relative '..\..\..\lib\dendroid\syntax\rule'
require_relative '..\..\..\lib\dendroid\grm_analysis\rule_items'

describe Dendroid::GrmAnalysis::RuleItems do
  let(:num_symb) { Dendroid::Syntax::Terminal.new('NUMBER') }
  let(:plus_symb) { Dendroid::Syntax::Terminal.new('PLUS') }
  let(:star_symb) { Dendroid::Syntax::Terminal.new('STAR') }
  let(:expr_symb) { Dendroid::Syntax::NonTerminal.new('expression') }
  let(:alt1) { Dendroid::Syntax::SymbolSeq.new([num_symb, plus_symb, num_symb]) }
  let(:alt2) { Dendroid::Syntax::SymbolSeq.new([num_symb, star_symb, num_symb]) }
  let(:alt3) { Dendroid::Syntax::SymbolSeq.new([]) }
  subject do
    choice = Dendroid::Syntax::Rule.new(expr_symb, [alt1, alt2, alt3])
    choice.extend(Dendroid::GrmAnalysis::RuleItems)
    choice.build_items
    choice
  end

  context 'Methods from mix-in' do
    it 'builds items for given choice' do
      expect(subject.items.size).to eq(subject.alternatives.size)
      subject.items.each_with_index do |itemz, index|
        expect(itemz.size).to eq(subject.alternatives[index].size + 1)
      end
      arr_items = subject.items[1]
      arr_items.each_with_index do |item, pos|
        expect(item.rule).to eq(subject)
        expect(item.position).to eq(pos)
        expect(item.alt_index).to eq(1)
      end
      sole_item = subject.items[2].first # empty alternative...
      expect(sole_item.rule).to eq(subject)
      expect(sole_item.position).to eq(0)
      expect(sole_item.alt_index).to eq(2)
    end

    it 'returns the first (predicted) items of the choice' do
      expect(subject.predicted_items.size).to eq(subject.alternatives.size)
      expectations = [
        subject.items[0].first,
        subject.items[1].first,
        subject.items[2].first
      ]
      expect(subject.predicted_items).to eq(expectations)
    end

    it 'returns the last (reduce) items of the choice' do
      expect(subject.reduce_items.size).to eq(subject.alternatives.size)
      expectations = [
        subject.items[0].last,
        subject.items[1].last,
        subject.items[2].last
      ]
      expect(subject.reduce_items).to eq(expectations)
    end

    it 'returns the consecutive item to a given one' do
      arr_items = subject.items[1]
      (0..arr_items.size - 1).each do |pos|
        curr_item = arr_items[pos]
        next_one = subject.next_item(curr_item)
        expect(next_one).to eq(arr_items[pos + 1])
      end
      expect(subject.next_item(arr_items.last)).to be_nil
    end
  end # context
end # describe
