# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../support/sample_grammars'
require_relative '../../../lib/dendroid/grm_analysis/grm_analyzer'

describe Dendroid::GrmAnalysis::GrmAnalyzer do
  include SampleGrammars
  let(:grammar) { grammar_l1 }

  subject { described_class.new(grammar) }

  context 'Initialization:' do
    it 'is initialized with a grammar' do
      expect { described_class.new(grammar) }.not_to raise_error
    end

    it 'knows its related grammar' do
      expect(subject.grammar).to eq(grammar)
    end

    it 'knows the dotted items' do
      item_count = subject.grammar.rules.reduce(0) do |count, prod|
        count + prod.items.flatten.size
      end
      expect(subject.items.size).to eq(item_count)
      expected_items = [
        'p => . s',
        'p => s .',
        's => . s PLUS m',
        's => s . PLUS m',
        's => s PLUS . m',
        's => s PLUS m .',
        's => . m',
        's => m .',
        'm => . m STAR t',
        'm => m . STAR t',
        'm => m STAR . t',
        'm => m STAR t .',
        'm => . t',
        'm => t .',
        't => . INTEGER',
        't => INTEGER .'
      ]
      expect(subject.items.map(&:to_s)).to eq(expected_items)
    end

    it 'knows the item that follows a given dotted item' do
      first_item = subject.items.find { |itm| itm.to_s == 'm => . m STAR t' }
      second = subject.next_item(first_item)
      expect(second.to_s).to eq('m => m . STAR t')
      third = subject.next_item(second)
      expect(third.to_s).to eq('m => m STAR . t')
      fourth = subject.next_item(third)
      expect(fourth.to_s).to eq('m => m STAR t .')
      expect(subject.next_item(fourth)).to be_nil
    end
  end # context

  context 'Provided services:' do
    subject { described_class.new(grammar_l3) }
    it 'constructs the FIRST sets of grammar symbols' do
      expectations = {
        'a' => ['a'],
        'c' => ['c'],
        'd' => ['d'],
        'X' => %w[a c], # Add epsilon
        'Y' => ['c'], # Add epsilon
        'Z' => %w[a c d]
      }
      expectations.each_pair do |sym_name, first_names|
        symb = subject.grammar.name2symbol[sym_name]
        expected_first = first_names.map { |name| subject.grammar.name2symbol[name] }
        expected_first << subject.epsilon if sym_name =~ /[XY]/
        expect(subject.first_sets[symb]).to eq(Set.new(expected_first))
      end
    end

    it 'constructs the FOLLOW sets for non-terminal symbols' do
      expectations = {
        'Z' => [], # Add $$
        'Y' => %w[a c d],
        'X' => %w[a c d]
      }
      subject.send(:build_follow_sets)
      expectations.each_pair do |sym_name, follow_names|
        symb = subject.grammar.name2symbol[sym_name]
        expected_follow = follow_names.map { |name| subject.grammar.name2symbol[name] }
        expected_follow << subject.endmarker if sym_name == 'Z'
        expect(subject.follow_sets[symb]).to eq(Set.new(expected_follow))
      end
    end
  end # context
end # describe
