# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\syntax\terminal'
require_relative '..\..\..\lib\dendroid\syntax\non_terminal'
require_relative '..\..\..\lib\dendroid\syntax\symbol_seq'
require_relative '..\..\..\lib\dendroid\syntax\production'
require_relative '..\..\..\lib\dendroid\syntax\choice'
require_relative '..\..\..\lib\dendroid\syntax\grammar'
require_relative '..\..\..\lib\dendroid\grm_dsl\base_grm_builder'

describe Dendroid::Syntax::Grammar do
  let(:int_symb) { build_terminal('INTEGER') }
  let(:plus_symb) { build_terminal('PLUS') }
  let(:star_symb) { build_terminal('STAR') }
  let(:p_symb) { build_nonterminal('p') }
  let(:s_symb) { build_nonterminal('s') }
  let(:m_symb) { build_nonterminal('m') }
  let(:t_symb) { build_nonterminal('t') }
  let(:all_terminals) { [int_symb, plus_symb, star_symb] }

  subject { described_class.new(all_terminals) }

  def build_terminal(name)
    Dendroid::Syntax::Terminal.new(name)
  end

  def build_nonterminal(name)
    Dendroid::Syntax::NonTerminal.new(name)
  end

  def build_symbol_seq(symbols)
    Dendroid::Syntax::SymbolSeq.new(symbols)
  end

  def build_production(lhs, symbols)
    Dendroid::Syntax::Production.new(lhs, build_symbol_seq(symbols))
  end

  def build_choice(lhs, sequences)
    Dendroid::Syntax::Choice.new(lhs, sequences.map { |arr| build_symbol_seq(arr) })
  end

  def build_all_rules
    rule1 = build_production(p_symb, [s_symb]) # p => s
    rule2 = build_choice(s_symb, [[s_symb, plus_symb, m_symb], [m_symb]]) # s => s + m | m
    rule3 = build_choice(m_symb, [[m_symb, star_symb, t_symb], [t_symb]]) # m => m * t
    rule4 = build_production(t_symb, [int_symb]) # t => INTEGER
    [rule1, rule2, rule3, rule4]
  end

  context 'Initialization:' do
    it 'is initialized with an array of terminal symbols' do
      expect { described_class.new(all_terminals) }.not_to raise_error
    end

    it 'knows its terminal symbols' do
      expect(subject.symbols).to eq(all_terminals)
    end

    it 'ignores about productions after initialization' do
      expect(subject.rules).to be_nil
    end

    it 'maps a terminal name to one GrmSymbol object' do
      expect(subject.name2symbol.values.uniq.size).to eq(all_terminals.size)
      expect(subject.name2symbol.values.size).to eq(2 * all_terminals.size)
      expect(subject.name2symbol[:PLUS]).to eq(plus_symb)
      expect(subject.name2symbol['PLUS']).to eq(plus_symb)
    end
  end # context

  context 'Adding productions:' do
    it 'allows the addition of one production rule' do
      rule = build_production(p_symb, [s_symb])
      expect { subject.add_rule(rule) }.not_to raise_error
      expect(subject.rules.size).to eq(1)
      expect(subject.rules.first).to eq(rule)
    end

    it 'allows the addition of multiple production rules' do
      rules = build_all_rules
      rules.each { |rl| subject.add_rule(rl) }
      expect(subject.rules.size).to eq(4)
      expect(subject.rules.first).to eq(rules.first)
      expect(subject.rules.last).to eq(rules.last)
    end

    it 'updates the set of symbols when adding production rules' do
      rules = build_all_rules
      rules.each { |rl| subject.add_rule(rl) }
      [p_symb, s_symb, m_symb, t_symb].each do |symb|
        expect(subject.symbols.include?(symb)).to be_truthy
      end
    end

    it 'maps name of every non-terminal to its related GrmSymbol' do
      rules = build_all_rules
      rules.each { |rl| subject.add_rule(rl) }
      [[:p, p_symb],
       ['p', p_symb],
       [:s, s_symb],
       ['s', s_symb],
       [:m, m_symb],
       ['m', m_symb],
       [:t, t_symb],
       [:t, t_symb]].each do |(name, symb)|
        expect(subject.name2symbol[name]).to eq(symb)
      end
    end

    it 'maps every non-terminal to its defining productions' do
      rules = build_all_rules
      rules.each { |rl| subject.add_rule(rl) }
      %i[p s m t].each do |symb_name|
        symb = subject.name2symbol[symb_name]
        expected_prods = subject.rules.select { |prd| prd.head == symb }
        related_prods = subject.nonterm2productions[symb]
        expect(related_prods).to eq(expected_prods)
      end
    end
  end # context

  context 'Grammar completion:' do
    it 'detects and marks nullable symbols (I)' do
      # Case: grammar without nullable symbols
      rules = build_all_rules
      rules.each { |rl| subject.add_rule(rl) }
      subject.complete!
      expect(subject.symbols.none?(&:nullable?)).to be_truthy
    end

    it 'detects and marks nullable symbols (II)' do
      # Case: grammar with only nullable symbols
      # Grammar inspired for paper "Practical Earley Parser"
      terminal_a = build_terminal('a')
      nterm_s_prime = build_nonterminal("S'")
      nterm_s = build_nonterminal('S')
      nterm_a = build_nonterminal('A')
      nterm_e = build_nonterminal('E')

      instance = described_class.new([terminal_a])
      instance.add_rule(build_production(nterm_s_prime, [nterm_s]))
      instance.add_rule(build_production(nterm_s, [nterm_a, nterm_a, nterm_a, nterm_a]))
      instance.add_rule(build_choice(nterm_a, [[terminal_a], [nterm_e]]))
      instance.add_rule(build_production(nterm_e, []))

      instance.complete!
      all_nonterminals = subject.symbols.reject(&:terminal?)
      expect(all_nonterminals.all?(&:nullable?)).to be_truthy
    end

    it 'detects unreachable symbols' do
      # Case: grammar without unreachable symbols
      rules = build_all_rules
      rules.each { |rl| subject.add_rule(rl) }
      expect(subject.send(:unreachable_symbols)).to be_empty

      # Let add's unreachable symbols
      zed_symb = build_nonterminal('Z')
      question_symb = build_nonterminal('?')
      bad_rule = build_production(zed_symb, [zed_symb, question_symb, int_symb]) # Z => Z ? INTEGER
      subject.add_rule(bad_rule)
      unreachable = subject.send(:unreachable_symbols)
      expect(unreachable).not_to be_empty
      expect(unreachable).to eq(Set.new([zed_symb, question_symb]))
    end

    it 'detects non-productive symbols' do
      # Case: grammar without non-productive symbols
      rules = build_all_rules
      rules.each { |rl| subject.add_rule(rl) }
      expect(subject.send(:mark_non_productive_symbols)).to be_empty
      expect(t_symb).to be_productive
      expect(p_symb).to be_productive

      # Grammar with non-productive symbols
      term_a = build_terminal('a')
      term_b = build_terminal('b')
      term_c = build_terminal('c')
      term_d = build_terminal('d')
      term_e = build_terminal('e')
      term_f = build_terminal('f')
      nterm_A = build_nonterminal('A')
      nterm_B = build_nonterminal('B')
      nterm_C = build_nonterminal('C')
      nterm_D = build_nonterminal('D')
      nterm_E = build_nonterminal('E')
      nterm_F = build_nonterminal('F')
      nterm_S = build_nonterminal('S')
      instance = described_class.new([term_a, term_b, term_c, term_d, term_e, term_f])
      instance.add_rule(build_choice(nterm_S, [[nterm_A, nterm_B], [nterm_D, nterm_E]]))
      instance.add_rule(build_production(nterm_A, [term_a]))
      instance.add_rule(build_production(nterm_B, [term_b, nterm_C]))
      instance.add_rule(build_production(nterm_C, [term_c]))
      instance.add_rule(build_production(nterm_D, [term_d, nterm_F]))
      instance.add_rule(build_production(nterm_E, [term_e]))
      instance.add_rule(build_production(nterm_F, [term_f, nterm_D]))
      nonproductive = instance.send(:mark_non_productive_symbols)
      expect(nonproductive).not_to be_empty
      expect(nonproductive).to eq([nterm_D, nterm_F])
    end
  end # context

  context 'Errors with terminal symbols' do
    def grm_terminal_in_lhs
      builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
        declare_terminals('a', 'b', 'c')

        rule 'S' => 'A'
        rule 'a' => 'a A c' # Wrong: terminal 'a' in lhs
        rule 'A' => 'b'
      end

      builder.grammar
    end

    def grm_cyclic
      builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
        declare_terminals('x')

        rule 'S' => %w[S x] # Wrong: cyclic production (lhs and rhs are the same)
      end

      builder.grammar
    end

    def grm_no_terminal
      builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
        # No terminal symbol explicitly declared => all symbols are non-terminals

        rule 'S' => 'A'
        rule 'A' => 'a A c'
        rule 'A' => 'b'
      end

      builder.grammar
    end

    def unused_terminals
      builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
        declare_terminals('a', 'b', 'c', 'd', 'e')

        # # Wrong: terminals 'd' and 'e' never appear in rules
        rule 'S' => 'A'
        rule 'A' => 'a A c'
        rule 'A' => 'b'
      end

      builder.grammar
    end

    it 'raises an error if there is no terminal symbol' do
      err_msg = "Grammar doesn't contain any terminal symbol."
      expect { grm_no_terminal }.to raise_error(StandardError, err_msg)
    end

    it 'raises an error if a terminal is in lhs of production' do
      err_msg = "Terminal symbol 'a' may not be on left-side of a rule."
      expect { grm_terminal_in_lhs }.to raise_error(StandardError, err_msg)
    end

    it 'raises an error if a terminal never appear in rules' do
      err_msg = "Terminal symbols 'd', 'e' never appear in production rules."
      expect { unused_terminals }.to raise_error(StandardError, err_msg)
    end

    it 'raises an error if a production is cyclic' do
      err_msg = 'Cyclic rules of the kind S => S are not allowed.'
      expect { grm_cyclic }.to raise_error(StandardError, err_msg)
    end
  end # context

  context 'Errors with non-terminal symbols' do
    def grm_undefined_nterm
      builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
        declare_terminals('x')

        rule 'S' => %w[x A] # Wrong: A is never defined
      end

      builder.grammar
    end

    def duplicate_production
      builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
        declare_terminals('a', 'b', 'c')

        rule 'S' => 'A'
        rule 'A' => ['a A c', 'b']
        rule 'S' => 'A' # Duplicate rule
      end

      builder.grammar
    end

    def grm_unreachable_symbols
      builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
        declare_terminals('a', 'b', 'c')

        rule 'S' => 'A'
        rule 'A' => ['a A c', 'b']
        rule 'Z' => 'a Z X'
        rule 'X' => 'b b'
      end

      builder.grammar
    end

    def nonproductive_symbols
      builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
        declare_terminals('a', 'b', 'c', 'd', 'e', 'f')

        # # Wrong: terminals 'D' and 'F' are non-productive (they never reduce to a string of terminals)
        rule 'S' => ['A B', 'D E']
        rule 'A' => 'a'
        rule 'B' => 'b C'
        rule 'C' => 'c'
        rule 'D' => 'd F'
        rule 'E' => 'e'
        rule 'F' => 'f D'
      end

      builder.grammar
    end

    it 'raises an error when a non-terminal is never defined' do
      err_msg = "Non-terminal symbols 'A' never appear in head of any production rule."
      expect { grm_undefined_nterm }.to raise_error(StandardError, err_msg)
    end

    it 'raises an error when a production is duplicated' do
      err_msg = "Production rule 'S => A' appears more than once in the grammar."
      expect { duplicate_production }.to raise_error(StandardError, err_msg)
    end

    it 'raises an error when a non-terminal is unreachable' do
      # err_msg = "Symbols 'Z', 'X' are unreachable from start symbol."
      err_msg = "Symbols 'Z' are non-productive."
      expect { grm_unreachable_symbols }.to raise_error(StandardError, err_msg)
    end

    it 'raises an error when a non-terminal is non-productive' do
      err_msg = "Symbols 'D', 'F' are non-productive."
      expect { nonproductive_symbols }.to raise_error(StandardError, err_msg)
    end
  end # contex
end # describe
