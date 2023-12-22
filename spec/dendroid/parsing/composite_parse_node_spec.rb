# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/dendroid/parsing/composite_parse_node'

RSpec.describe Dendroid::Parsing::CompositeParseNode do
  let(:sample_range) { 3..5 }
  let(:sample_child_count) { 7 }
  subject { described_class.new(sample_range.begin, sample_range.end, sample_child_count) }

  context 'Initialization:' do
    it 'should be initialized with two token positions and a child count' do
      expect { described_class.new(sample_range.begin, sample_range.end, sample_child_count) }.not_to raise_error
    end

    it 'has its children array filled with nils' do
      # Check number of elements...
      expect(subject.children.size).to eq(sample_child_count)

      # All elements are nil
      expect(subject.children.all?(&:nil?)).to be_truthy
    end
  end # context

  context 'provided services:' do
    it 'adds a child node at a specific slot' do
      child3 = Dendroid::Parsing::ParseNode.new(3, 4)
      child5 = Dendroid::Parsing::ParseNode.new(5, 6)
      subject.add_child(child3, 3)
      subject.add_child(child5, 5)
      expect(subject.children.reject(&:nil?).size).to eq(2)
      expect(subject.children[3]).to eq(child3)
      expect(subject.children[5]).to eq(child5)
    end
  end # context
end # describe
