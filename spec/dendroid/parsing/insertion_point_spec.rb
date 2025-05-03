# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../support/sample_grammars'
require_relative '../../../lib/dendroid/parsing/insertion_point'
require_relative '../../../lib/dendroid/recognizer/recognizer'

RSpec.describe Dendroid::Parsing::InsertionPoint do
  include SampleGrammars

  let(:and_node) { Dendroid::Parsing::AndNode.new(success_entry, 2) }
  let(:default_state) { Dendroid::Parsing::PointState.new }
  let(:dotted_two) { prod.items[0][-1] }
  let(:prod) { sample_grammar.rules.first }
  let(:recognizer) do
    Dendroid::Recognizer::Recognizer.new(sample_grammar, tokenizer_l8)
  end
  let(:sample_chart) { recognizer.run('x x x') }
  let(:sample_grammar) { grammar_l8 }
  let(:sample_thread_id) { 3 }
  let(:success_entry) { sample_chart.success_entry }
  let(:terminal_node) { Dendroid::Parsing::TerminalNode.new(x_symb, double('dummy toke'), 2) }
  let(:x_symb) { sample_grammar.name2symbol['x'] }

  context 'Initialization as root:' do
    subject { described_class.new(sample_thread_id, nil, and_node, default_state) }

    it 'is initialized with a nil second argument' do
      # Case of root node: no parent ipoint
      expect { described_class.new(sample_thread_id, nil, and_node, default_state) }.not_to raise_error
    end

    it 'knows its node' do
      expect(subject.node).to be_equal(and_node)
    end

    it 'knows its state object' do
      expect(subject.state).to eq(default_state)
    end

    it 'knows its origin' do
      expect(subject.origin).to eq(success_entry.origin)
    end

    it 'has no parent' do
      expect(subject.parents).to be_empty
    end

    it 'is not full' do
      expect(subject).to_not be_full
    end

    it 'has a dot at end position' do
      expected_pos = subject.node.children.size
      expect(subject.dot_pos).to eq(expected_pos)
    end

    it 'is not shared at initialization' do
      expect(subject).not_to be_shared
    end
  end # context

  context 'Initialization as child:' do
    let(:top_parent) { described_class.new(sample_thread_id, nil, and_node, default_state) }
    subject do
      described_class.new(sample_thread_id, top_parent, terminal_node, default_state)
    end

    it 'is initialized with a parent argument' do
      expect { described_class.new(sample_thread_id, top_parent, terminal_node, default_state) }.not_to raise_error
    end

    it 'knows its parent' do
      expect(subject.parents[0]).to be_equal(top_parent)
    end
  end # context

  context 'Behaviour in default state' do
    subject {  described_class.new(sample_thread_id, nil, and_node, default_state) }

    it 'knows its related dotted item' do
      expect(subject.dotted_item).to be_equal(dotted_two)
    end

    it 'gives a text representation of itself with AndNode' do
      expect(subject.to_s).to eq('S => S S ^ [0..2]')
      subject.tick
      expect(subject.to_s).to eq('S => S ^ S [0..2]')
      subject.tick
      expect(subject.to_s).to eq('S => S S [0..2]')
    end

    it 'gives a text representation of itself with TerminalNode' do
      instance = described_class.new(sample_thread_id, nil, terminal_node, default_state)
      allow(instance.node.token).to receive(:literal?).and_return(false)
      expect(instance.to_s).to eq('x [2..3]')
    end

    it 'compares to a given entry irrespective of predecessor argument' do
      expect(subject.expect?(success_entry, 'dummy argument')).to be_falsey
    end

    # it 'can be shared' do
    #   subject.share
    #   expect(subject.is_shared).to be_truthy
    # end
  end
end # describe
