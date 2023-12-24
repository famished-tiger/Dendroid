# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../support/sample_grammars'
require_relative '../../../lib/dendroid/recognizer/recognizer'
require_relative '../../../lib/dendroid/parsing/walk_progress'

RSpec.describe Dendroid::Parsing::WalkProgress do
  include SampleGrammars

  def retrieve_success_item(chart, grammar)
    last_item_set = chart.item_sets.last
    result = nil
    last_item_set.items.reverse_each do |itm|
      if itm.origin.zero? && itm.dotted_item.completed? && itm.dotted_item.rule.lhs == grammar.start_symbol
        result = itm
        break
      end
    end

    result
  end

  def recognizer_for(grammar, tokenizer)
    Dendroid::Recognizer::Recognizer.new(grammar, tokenizer)
  end

  def success_entry(chart, recognizer)
    retrieve_success_item(chart, recognizer.grm_analysis.grammar)
  end

  subject do
    recognizer = recognizer_for(grammar_l8, tokenizer_l8)
    chart = recognizer.run('x x x x')
    described_class.new(4, success_entry(chart, recognizer), [])
  end

  context 'Initialization:' do
    it 'should be initialized with a symbol, terminal and a rank' do
      recognizer = recognizer_for(grammar_l8, tokenizer_l8)
      chart = recognizer.run('x x x x')
      expect { described_class.new(4, success_entry(chart, recognizer), []) }.not_to raise_error
    end

    it 'is in New state' do
      expect(subject.state).to eq(:New)
    end

    it 'has no overriding predecessor at start' do
      expect(subject.predecessor).to be_nil
    end

    it 'knows the current rank' do
      expect(subject.curr_rank).to eq(4)
    end

    it 'knows the current item' do
      expect(subject.curr_item.to_s).to eq('S => S S . @ 0')
    end
  end # context
end # describe
