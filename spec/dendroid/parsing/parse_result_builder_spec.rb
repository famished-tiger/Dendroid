# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../support/sample_grammars'
require_relative '../../../lib/dendroid/syntax/terminal'
require_relative '../../../lib/dendroid/syntax/non_terminal'
require_relative '../../../lib/dendroid/syntax/symbol_seq'
require_relative '../../../lib/dendroid/syntax/rule'
require_relative '../../../lib/dendroid/grm_analysis/rule_items'
require_relative '../../../lib/dendroid/recognizer/e_item'
require_relative '../../../lib/dendroid/recognizer/recognizer'
require_relative '../../../lib/dendroid/parsing/parse_result_builder'

RSpec.describe Dendroid::Parsing::ParseResultBuilder do
  include SampleGrammars

  def recognizer_for(grammar, tokenizer)
    Dendroid::Recognizer::Recognizer.new(grammar, tokenizer)
  end

  def chart_for(grammar, tokenizer, source)
    recognizer = Dendroid::Recognizer::Recognizer.new(grammar, tokenizer)
    recognizer.run(source)
  end

  def init_visit(chart, instance)
    visitor = Dendroid::Parsing::ChartVisitor.new(chart)
    ctx = visitor.context_for(instance)
    instance.start(ctx)

    ctx
  end

  subject { described_class.new }

  context 'Initialization:' do
    let(:sample_chart) do
      recognizer = recognizer_for(grammar_l1, tokenizer_l1)
      recognizer.run('2 + 3 * 4')
    end

    it 'should be initialized without argument' do
      expect { described_class.new }.not_to raise_error
    end
  end # context


  context 'Parse recursive rules' do
    it 'copes with immediate left recursive rule (l10, empty input)' do
      recognizer = recognizer_for(grammar_l10, tokenizer_l10)
      chart = recognizer.run('')
      root = subject.run(chart)
      expect(root.to_s).to eq('A =>  [0..0]')

      expect(root.children.size).to be_zero
    end

    it 'copes with immediate left recursive rule (l10, one token)' do
      recognizer = recognizer_for(grammar_l10, tokenizer_l10)
      chart = recognizer.run('a')
      root = subject.run(chart)
      expect(root.to_s).to eq('A => A a [0..1]')
      expect(root.children.size).to eq(2)
      (ch_0, ch_1) = root.children
      expect(ch_1.to_s).to eq('a [0..1]')
      expect(ch_0.to_s).to eq('A =>  [0..0]')
    end

    it 'copes with immediate left recursive rule (l10, two tokens)' do
      recognizer = recognizer_for(grammar_l10, tokenizer_l10)
      chart = recognizer.run('a a')
      puts chart.to_text
      root = subject.run(chart)
      expect(root.to_s).to eq('A => A a [0..2]')
      expect(root.children.size).to eq(2)
      (ch_0, ch_1) = root.children
      expect(ch_1.to_s).to eq('a [1..2]')
      expect(ch_0.to_s).to eq('A => A a [0..1]')
    end

    it 'copes with immediate right recursive rule (l11, empty input)' do
      recognizer = recognizer_for(grammar_l11, tokenizer_l11)
      chart = recognizer.run('')
      root = subject.run(chart)
      expect(root.to_s).to eq('A =>  [0..0]')

      expect(root.children.size).to be_zero
    end

    it 'copes with immediate right recursive rule (l11, one token)' do
      recognizer = recognizer_for(grammar_l11, tokenizer_l11)
      chart = recognizer.run('a')
      puts chart.to_text
      root = subject.run(chart)
      expect(root.to_s).to eq('A => a A [0..1]')
      expect(root.children.size).to eq(2)
      (ch_0, ch_1) = root.children
      expect(ch_0.to_s).to eq('a [0..1]')
      expect(ch_1.to_s).to eq('A =>  [1..1]')
    end

    it 'copes with immediate right recursive rule (l11, two tokens)' do
      recognizer = recognizer_for(grammar_l11, tokenizer_l11)
      chart = recognizer.run('a a')
      puts chart.to_text
      root = subject.run(chart)
      expect(root.to_s).to eq('A => a A [0..2]')
      expect(root.children.size).to eq(2)
      (ch_0, ch_1) = root.children
      expect(ch_0.to_s).to eq('a [0..1]') # FAILS
      expect(ch_1.to_s).to eq('A => a A [1..2]')

      (ch_1_0, ch_1_1) = ch_1.children
      expect(ch_1_0.to_s).to eq('a [1..2]')
      expect(ch_1_1.to_s).to eq('A =>  [2..2]')
    end

    it 'copes with hidden left recursive rule (l18, two tokens)' do
      recognizer = recognizer_for(grammar_l18, tokenizer_l18)
      chart = recognizer.run('a a')
      root = subject.run(chart)
      expect(root.to_s).to eq('S => X S a [0..2]')
      expect(root.children.size).to eq(3)
      (ch_0, ch_1, ch_2) = root.children
      expect(ch_0.to_s).to eq('X =>  [0..0]')
      expect(ch_1.to_s).to eq('S => a [0..1]')
      expect(ch_2.to_s).to eq('a [1..2]')

      expect(ch_1.children.size).to eq(1)
      expect(ch_1.children[0].to_s). to eq('a [0..1]')
    end

    it 'copes with hidden left recursive rule (l18, three tokens)' do
      recognizer = recognizer_for(grammar_l18, tokenizer_l18)
      chart = recognizer.run('a a a')
      puts chart.to_text
      root = subject.run(chart)
      expect(root.to_s).to eq('S => X S a [0..3]')
      expect(root.children.size).to eq(3)
      (ch_0, ch_1, ch_2) = root.children
      expect(ch_0.to_s).to eq('X =>  [0..0]')
      expect(ch_1.to_s).to eq('S => X S a [0..2]')
      expect(ch_2.to_s).to eq('a [2..3]')

      expect(ch_1.children.size).to eq(3)
      (ch_1_0, ch_1_1, ch_1_2) = ch_1.children
      expect(ch_1_0.to_s).to eq('X =>  [0..0]')
      expect(ch_1_1.to_s).to eq('S => a [0..1]')
      expect(ch_1_2.to_s).to eq('a [1..2]')

      expect(ch_1_1.children[0].to_s).to eq('a [0..1]')
    end

    it 'copes with hidden right recursive rule (l19, two tokens)' do
      recognizer = recognizer_for(grammar_l19, tokenizer_l19)
      chart = recognizer.run('a a')
      root = subject.run(chart)
      expect(root.to_s).to eq('S => a S X [0..2]')
      expect(root.children.size).to eq(3)
      (ch_0, ch_1, ch_2) = root.children
      expect(ch_0.to_s).to eq('a [0..1]')
      expect(ch_1.to_s).to eq('S => a [1..2]')
      expect(ch_2.to_s).to eq('X =>  [2..2]')

      expect(ch_1.children.size).to eq(1)
      expect(ch_1.children[0].to_s). to eq('a [1..2]')
    end

    it 'copes with hidden right recursive rule (l19, three tokens)' do
      recognizer = recognizer_for(grammar_l19, tokenizer_l19)
      chart = recognizer.run('a a a')
      root = subject.run(chart)
      expect(root.to_s).to eq('S => a S X [0..3]')
      expect(root.children.size).to eq(3)
      (ch_0, ch_1, ch_2) = root.children
      expect(ch_0.to_s).to eq('a [0..1]')
      expect(ch_1.to_s).to eq('S => a S X [1..3]')
      expect(ch_2.to_s).to eq('X =>  [3..3]')

      expect(ch_1.children.size).to eq(3)
      (ch_1_0, ch_1_1, ch_1_2) = ch_1.children
      expect(ch_1_0.to_s).to eq('a [1..2]')
      expect(ch_1_1.to_s).to eq('S => a [2..3]')
      expect(ch_1_2.to_s).to eq('X =>  [3..3]')
      expect(ch_2).to equal(ch_1_2) # Test node sharing

      expect(ch_1_1.children[0].to_s).to eq('a [2..3]')
    end

    it 'generates a parse tree for doubly recursive grammar l8 and one token' do
      recognizer = recognizer_for(grammar_l8, tokenizer_l8)
      chart = recognizer.run('x')
      root = subject.run(chart)
      expect(root.to_s).to eq('S => x [0..1]')

      expect(root.children.size).to eq(1)
      expect(root.children[0].to_s).to eq('x [0..1]')
    end

    it 'generates a parse tree for grammar l8 and two tokens' do
      recognizer = recognizer_for(grammar_l8, tokenizer_l8)
      chart = recognizer.run('x x')
      root = subject.run(chart)
      expect(root.to_s).to eq('S => S S [0..2]')

      expect(root.children.size).to eq(2)
      expect(root.children[0].to_s).to eq('S => x [0..1]')
      expect(root.children[1].to_s).to eq('S => x [1..2]')
      expect(root.children[1].children[-1].to_s).to eq('x [1..2]')
    end

    it 'generates a parse tree for grammar l8 and three tokens' do
      recognizer = recognizer_for(grammar_l8, tokenizer_l8)
      chart = recognizer.run('x x x')
      puts chart.to_text
      root = subject.run(chart)
      expect(root.to_s).to eq('OR: S [0..3]')

      expect(root.children.size).to eq(2)
      root.children.each { |ch| expect(ch.to_s).to start_with('S => S S [0..3]_') }

      (a, b) = root.children
      expect(a.children.size).to eq(2)
      (a_0, a_1) = a.children
      expect(a_0.to_s).to eq('S => S S [0..2]')
      expect(a_1.to_s).to eq('S => x [2..3]')
      expect(a_1.children[0].to_s).to eq('x [2..3]')

      expect(a_0.children.size).to eq(2)
      (a_0_0, a_0_1) = a_0.children
      expect(a_0_0.to_s).to eq('S => x [0..1]')
      expect(a_0_0.children[0].to_s).to eq('x [0..1]')
      expect(a_0_1.to_s).to eq('S => x [1..2]')
      expect(a_0_1.children[0].to_s).to eq('x [1..2]')

      expect(b.children.size).to eq(2)
      (b_0, b_1) = b.children
      expect(b_0.to_s).to eq('S => x [0..1]')
      expect(b_0.equal?(a_0_0)).to be_truthy # Shared node
      expect(b_1.to_s).to eq('S => S S [1..3]')

      expect(b_1.children.size).to eq(2)
      (b_1_0, b_1_1) = b_1.children
      expect(b_1_0.to_s).to eq('S => x [1..2]')
      expect(b_1_0.equal?(a_0_1)).to be_truthy # Shared node
      expect(b_1_1.to_s).to eq('S => x [2..3]')
      expect(b_1_1.equal?(a_1)).to be_truthy # Shared node
    end

    it 'generates a parse tree for grammar l8 and four tokens' do
      recognizer = recognizer_for(grammar_l8, tokenizer_l8)
      chart = recognizer.run('x x x x')
      puts chart.to_text
      root = subject.run(chart)
      expect(root.to_s).to eq('OR: S [0..4]')
      expect(root.children.size).to eq(3)
      root.children.each_with_index do |ch, i|
        expect(ch.to_s).to eq("S => S S [0..4]_#{2 - i}")
        expect(ch.children.size).to eq(2)
      end
      (ch_0, ch_1, ch_2) = root.children

      # Testing backwards: top-down, right-to-left
      (ch_0_1, ch_1_1, ch_2_1) = root.children.map { |ch| ch.children.last }
      expect(ch_0_1.to_s).to eq('OR: S [1..4]')
      expect(ch_1_1.to_s).to eq('S => x [3..4]')
      expect(ch_1_1.children.first.to_s).to eq('x [3..4]')
      expect(ch_2_1.to_s).to eq('S => S S [2..4]')

      ch_0_1.children.each_with_index do |ch, i|
        expect(ch.to_s).to eq("S => S S [1..4]_#{1 - i}")
        expect(ch.children.size).to eq(2)
      end

      (ch_0_1_0_1, ch_0_1_1_1) = ch_0_1.children.map { |ch| ch.children.last }
      expect(ch_0_1_0_1.to_s).to eq('S => x [3..4]')
      expect(ch_0_1_0_1).to equal(ch_1_1) # Test sharing
      expect(ch_0_1_1_1.to_s).to eq('S => S S [2..4]')
      (ch_0_1_1_1_0, ch_0_1_1_1_1) = ch_0_1_1_1.children
      expect(ch_0_1_1_1_1.to_s).to eq('S => x [3..4]')
      expect(ch_0_1_1_1_1).to equal(ch_1_1) # Test sharing
      expect(ch_0_1_1_1_0.to_s).to eq('S => x [2..3]')
      expect(ch_0_1_1_1_0.children.first.to_s).to eq('x [2..3]')

      (ch_0_1_0_0, ch_0_1_1_0) = ch_0_1.children.map { |ch| ch.children.first }
      expect(ch_0_1_0_0.to_s). to eq('S => S S [1..3]')
      expect(ch_0_1_1_0.to_s). to eq('S => x [1..2]')
      expect(ch_0_1_1_0.children.first.to_s).to eq('x [1..2]')
      (ch_0_1_0_0_0, ch_0_1_0_0_1) = ch_0_1_0_0.children
      expect(ch_0_1_0_0_1.to_s).to eq('S => x [2..3]')
      expect(ch_0_1_0_0_1).to equal(ch_0_1_1_1_0) # Test sharing
      expect(ch_0_1_0_0_0.to_s).to eq('S => x [1..2]')
      expect(ch_0_1_0_0_0).to equal(ch_0_1_1_0)

      ch_1_0 = ch_1.children[0]
      expect(ch_1_0.to_s).to eq('OR: S [0..3]')
      ch_1_0.children.each_with_index do |ch, i|
        expect(ch.to_s).to eq("S => S S [0..3]_#{1 - i}")
        expect(ch.children.size).to eq(2)
      end

      (ch_1_0_0_1, ch_1_0_1_1) = ch_1_0.children.map { |ch| ch.children.last }
      expect(ch_1_0_0_1.to_s).to eq('S => x [2..3]')
      expect(ch_1_0_0_1).to equal(ch_0_1_1_1_0) # Test sharing
      expect(ch_1_0_1_1.to_s).to eq('S => S S [1..3]')
      expect(ch_1_0_1_1).to equal(ch_0_1_0_0) # Test sharing

      ch_2_0 = ch_2.children[0]
      expect(ch_2_0.to_s).to eq('S => S S [0..2]')
      (ch_2_0_0, ch_2_0_1) = ch_2_0.children
      expect(ch_2_0_1.to_s).to eq('S => x [1..2]')
      expect(ch_2_0_1).to equal(ch_0_1_1_0) # Test sharing
      expect(ch_2_0_0.to_s).to eq('S => x [0..1]')
      expect(ch_2_0_0.children.first.to_s).to eq('x [0..1]')

      (ch_1_0_0_0, ch_1_0_1_0) = ch_1_0.children.map { |ch| ch.children.first }
      expect(ch_1_0_0_0.to_s).to eq('S => S S [0..2]')
      expect(ch_1_0_0_0).to equal(ch_2_0) # Test sharing
      expect(ch_1_0_1_0.to_s).to eq('S => x [0..1]')
      expect(ch_1_0_1_0).to equal(ch_2_0_0) # Test sharing

      ch_0_0 = ch_0.children[0]
      expect(ch_0_0.to_s).to eq('S => x [0..1]')
      expect(ch_0_0).to equal(ch_2_0_0)
    end
  end # context
end # describe
