# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/dendroid/grm_dsl/base_grm_builder'
require_relative '../../../lib/dendroid/grm_analysis/dotted_item'
require_relative '../../../lib/dendroid/recognizer/e_item'
require_relative '../../../lib/dendroid/parsing/empty_rule_node'

RSpec.describe Dendroid::Parsing::EmptyRuleNode do
  let(:sample_rule) { sample_grammar.rules[0] }
  let(:sample_dotted_item) { Dendroid::GrmAnalysis::DottedItem.new(sample_rule, 0, 1) }
  let(:sample_entry) { Dendroid::Recognizer::EItem.new(sample_dotted_item, 5) }

  subject { described_class.new(sample_entry, 5) }

  let(:sample_grammar) do
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      declare_terminals('INTEGER')

      rule('s' => ['INTEGER', ''])
    end

    builder.grammar
  end

  context 'Initialization:' do
    it 'should be initialized with a chart entry and an end rank number' do
      expect { described_class.new(sample_entry, 5) }.not_to raise_error
    end

    it 'knows the rule it is related to' do
      expect(subject.rule).to eq(sample_grammar.rules[0])
    end

    it 'knows the alternative index it is related to' do
      expect(subject.alt_index).to eq(1)
    end

    it 'knows its origin and end positions' do
      expect(subject.range.begin).to eq(subject.range.end)
      expect(subject.range.begin).to eq(5)
    end
  end # context

  context 'Provided services:' do
    it 'renders a String representation of its range' do
      expect(subject.to_s).to eq('_ [5..5]')
    end
  end # context
end # describe
