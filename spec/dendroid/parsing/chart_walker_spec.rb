# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../support/sample_grammars'
require_relative '../../../lib/dendroid/recognizer/recognizer'
require_relative '../../../lib/dendroid/parsing/chart_walker'

# require_relative '../grm_dsl/base_grm_builder'
# require_relative '../utils/base_tokenizer'
# require_relative '../recognizer/recognizer'
# require_relative 'chart_walker'
# require_relative 'parse_tree_visitor'
# require_relative '../formatters/bracket_notation'
# require_relative '../formatters/ascii_tree'

RSpec.describe Dendroid::Parsing::ChartWalker do
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

  context 'Parsing non-ambiguous grammars' do
    it 'generates a parse tree for the example from Wikipedia' do
      recognizer = recognizer_for(grammar_l1, tokenizer_l1)
      chart = recognizer.run('2 + 3 * 4')
      walker = described_class.new(chart)
      root = walker.walk(success_entry(chart, recognizer))

      expect(root.to_s).to eq('p => s [0, 5]')
      expect(root.children.size). to eq(1)
      expect(root.children[-1].to_s).to eq('s => s PLUS m [0, 5]')
      plus_expr = root.children[-1]
      expect(plus_expr.children.size).to eq(3)
      expect(plus_expr.children[0].to_s).to eq('s => m [0, 1]')
      expect(plus_expr.children[1].to_s).to eq('PLUS [1, 2]')
      expect(plus_expr.children[2].to_s).to eq('m => m STAR t [2, 5]')

      operand_plus = plus_expr.children[0]
      expect(operand_plus.children.size).to eq(1)
      expect(operand_plus.children[0].to_s).to eq('m => t [0, 1]')
      expect(operand_plus.children[0].children.size).to eq(1)
      expect(operand_plus.children[0].children[0].to_s).to eq('t => INTEGER [0, 1]')
      expect(operand_plus.children[0].children[0].children[0].to_s).to eq('INTEGER: 2 [0, 1]')

      expect(plus_expr.children[1].to_s).to eq('PLUS [1, 2]')

      star_expr = plus_expr.children[2]
      expect(star_expr.children.size).to eq(3)
      expect(star_expr.children[0].to_s).to eq('m => t [2, 3]')
      expect(star_expr.children[1].to_s).to eq('STAR [3, 4]')
      expect(star_expr.children[2].to_s).to eq('t => INTEGER [4, 5]')

      operand_star = star_expr.children[0]
      expect(operand_star.children.size).to eq(1)
      expect(operand_star.children[0].to_s).to eq('t => INTEGER [2, 3]')
      expect(operand_star.children[0].children[0].to_s).to eq('INTEGER: 3 [2, 3]')

      expect(star_expr.children[2].children.size).to eq(1)
      expect(star_expr.children[2].children[0].to_s).to eq('INTEGER: 4 [4, 5]')
    end

    it 'generates a parse tree for grammar l10 (with left recursive rule)' do
      recognizer = recognizer_for(grammar_l10, tokenizer_l10)
      chart = recognizer.run('a a a a a')
      walker = described_class.new(chart)
      root = walker.walk(success_entry(chart, recognizer))

      expect(root.to_s).to eq('A => A a [0, 5]')
      expect(root.children.size). to eq(2)
      expect(root.children[0].to_s).to eq('A => A a [0, 4]')
      expect(root.children[1].to_s).to eq('a [4, 5]')

      expect(root.children[0].children.size).to eq(2)
      expect(root.children[0].children[0].to_s).to eq('A => A a [0, 3]')
      expect(root.children[0].children[1].to_s).to eq('a [3, 4]')

      grand_child = root.children[0].children[0]
      expect(grand_child.children.size).to eq(2)
      expect(grand_child.children[0].to_s).to eq('A => A a [0, 2]')
      expect(grand_child.children[1].to_s).to eq('a [2, 3]')

      expect(grand_child.children[0].children.size).to eq(2)
      expect(grand_child.children[0].children[0].to_s).to eq('A => A a [0, 1]')
      expect(grand_child.children[0].children[1].to_s).to eq('a [1, 2]')

      expect(grand_child.children[0].children[0].children.size).to eq(2)
      expect(grand_child.children[0].children[0].children[0].to_s).to eq('_ [0, 0]')
      expect(grand_child.children[0].children[0].children[1].to_s).to eq('a [0, 1]')
    end

    it 'generates a parse tree for grammar l11 (with right recursive rule)' do
      recognizer = recognizer_for(grammar_l11, tokenizer_l11)
      chart = recognizer.run('a a a a a')
      walker = described_class.new(chart)
      root = walker.walk(success_entry(chart, recognizer))

      expect(root.to_s).to eq('A => a A [0, 5]')
      expect(root.children.size). to eq(2)
      expect(root.children[0].to_s).to eq('a [0, 1]')
      expect(root.children[1].to_s).to eq('A => a A [1, 5]')

      expect(root.children[1].children.size).to eq(2)
      expect(root.children[1].children[0].to_s).to eq('a [1, 2]')
      expect(root.children[1].children[1].to_s).to eq('A => a A [2, 5]')

      grand_child = root.children[1].children[1]
      expect(grand_child.children.size).to eq(2)
      expect(grand_child.children[0].to_s).to eq('a [2, 3]')
      expect(grand_child.children[1].to_s).to eq('A => a A [3, 5]')

      expect(grand_child.children[1].children.size).to eq(2)
      expect(grand_child.children[1].children[0].to_s).to eq('a [3, 4]')
      expect(grand_child.children[1].children[1].to_s).to eq('A => a A [4, 5]')

      expect(grand_child.children[1].children[1].children.size).to eq(2)
      expect(grand_child.children[1].children[1].children[0].to_s).to eq('a [4, 5]')
      expect(grand_child.children[1].children[1].children[1].to_s).to eq('_ [5, 5]')
    end
  end # context

  context 'Parsing ambiguous grammars' do
    it "generates a parse forest for the G2 grammar that choked Earley's parsing algorithm" do
      recognizer = recognizer_for(grammar_l8, tokenizer_l8)
      chart = recognizer.run('x x x x')
      walker = described_class.new(chart)
      root = walker.walk(success_entry(chart, recognizer))

      expect(root.to_s).to eq('OR: S [0, 4]')
      expect(root.children.size). to eq(3)
      root.children.each do |child|
        expect(child.children.size).to eq(2)
        expect(child.to_s).to eq('S => S S [0, 4]')
      end
      (a, b, c) = root.children

      # Test structure of tree a
      (child_a_0, child_a_1) = a.children
      expect(child_a_0.to_s).to eq('S => S S [0, 2]')
      expect(child_a_1.to_s).to eq('S => S S [2, 4]')
      expect(child_a_0.children.size).to eq(2)
      (child_a_0_0, child_a_0_1) = child_a_0.children
      expect(child_a_0_0.to_s).to eq('S => x [0, 1]')
      expect(child_a_0_1.to_s).to eq('S => x [1, 2]')
      expect(child_a_0_0.children[0].to_s).to eq('x [0, 1]')
      expect(child_a_0_1.children[0].to_s).to eq('x [1, 2]')

      expect(child_a_1.children.size).to eq(2)
      (child_a_1_0, child_a_1_1) = child_a_1.children
      expect(child_a_1_0.to_s).to eq('S => x [2, 3]')
      expect(child_a_1_1.to_s).to eq('S => x [3, 4]')
      expect(child_a_1_0.children[0].to_s).to eq('x [2, 3]')
      expect(child_a_1_1.children[0].to_s).to eq('x [3, 4]')

      # Test structure of forest b
      (child_b_0, child_b_1) = b.children
      expect(child_b_0.to_s).to eq('OR: S [0, 3]')
      expect(child_b_1.to_s).to eq('S => x [3, 4]')
      expect(child_b_1.equal?(child_a_1_1)).to be_truthy # Sharing
      expect(child_b_0.children.size).to eq(2)
      (child_b_0_0, child_b_0_1) = child_b_0.children
      expect(child_b_0_0.to_s).to eq('S => S S [0, 3]')
      expect(child_b_0_1.to_s).to eq('S => S S [0, 3]')
      expect(child_b_0_0.children.size).to eq(2)
      (child_b_0_0_0, child_b_0_0_1) = child_b_0_0.children
      expect(child_b_0_0_0.to_s).to eq('S => x [0, 1]')
      expect(child_b_0_0_0.equal?(child_a_0_0)).to be_truthy # Sharing
      expect(child_b_0_0_1.to_s).to eq('S => S S [1, 3]')
      expect(child_b_0_0_1.children.size).to eq(2)
      expect(child_b_0_0_1.children[0].to_s).to eq('S => x [1, 2]')
      expect(child_b_0_0_1.children[0].equal?(child_a_0_1)).to be_truthy # Sharing
      expect(child_b_0_0_1.children[1].to_s).to eq('S => x [2, 3]')
      expect(child_b_0_0_1.children[1].equal?(child_a_1_0)).to be_truthy # Sharing

      expect(child_b_0_1.children.size).to eq(2)
      (child_b_0_1_0, child_b_0_1_1) = child_b_0_1.children
      expect(child_b_0_1_0.to_s).to eq('S => S S [0, 2]')
      expect(child_b_0_1_0.equal?(child_a_0)).to be_truthy # Sharing
      expect(child_b_0_1_1.to_s).to eq('S => x [2, 3]')
      expect(child_b_0_1_1.equal?(child_a_1_0)).to be_truthy # Sharing

      # Test structure of forest c
      (child_c_0, child_c_1) = c.children
      expect(child_c_0.to_s).to eq('S => x [0, 1]')
      expect(child_c_0.equal?(child_a_0_0)).to be_truthy # Sharing
      expect(child_c_1.to_s).to eq('OR: S [1, 4]')
      expect(child_c_1.children.size).to eq(2)
      (child_c_1_0, child_c_1_1) = child_c_1.children
      expect(child_c_1_0.to_s).to eq('S => S S [1, 4]')
      expect(child_c_1_1.to_s).to eq('S => S S [1, 4]')
      expect(child_c_1_0.children.size).to eq(2)
      (child_c_1_0_0, child_c_1_0_1) = child_c_1_0.children
      expect(child_c_1_0_0.to_s).to eq('S => x [1, 2]')
      expect(child_c_1_0_0.equal?(child_a_0_1)).to be_truthy # Sharing
      expect(child_c_1_0_1.to_s).to eq('S => S S [2, 4]')
      expect(child_c_1_0_1.equal?(child_a_1)).to be_truthy # Sharing
      (child_c_1_1_0, child_c_1_1_1) = child_c_1_1.children
      expect(child_c_1_1_0.to_s).to eq('S => S S [1, 3]')
      expect(child_c_1_1_0.equal?(child_b_0_0_1)).to be_truthy # Sharing
      expect(child_c_1_1_1.to_s).to eq('S => x [3, 4]')
      expect(child_c_1_1_1.equal?(child_b_1)).to be_truthy # Sharing
    end
  end # context
end # describe


