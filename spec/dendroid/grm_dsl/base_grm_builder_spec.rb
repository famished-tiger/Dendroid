# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\grm_dsl\base_grm_builder'

describe Dendroid::GrmDSL::BaseGrmBuilder do
  # Builds ingredients for a grammar inspired from https://en.wikipedia.org/wiki/Earley_parser
  subject do
    instance = described_class.new
    instance.declare_terminals('PLUS', 'STAR', 'INTEGER')
    instance
  end

  context 'Initialization:' do
    it 'is initialized with an optional code block' do
      expect { described_class.new }.not_to raise_error
    end

    it 'is in "declaring" state by default' do
      expect(described_class.new.state).to eq(:declaring)
    end

    it 'has no grammar symbol by default' do
      expect(described_class.new.symbols).to be_empty
    end

    it 'has no production rule by default' do
      expect(described_class.new.rules).to be_empty
    end
  end # context

  context 'Provided services:' do
    it 'builds declared terminal symbols' do
      instance = described_class.new
      terminals = %w[PLUS STAR INTEGER]
      instance.declare_terminals(*terminals)
      expect(instance.symbols.size).to eq(2 * terminals.size)
      expect(instance.symbols[:PLUS]).to be_kind_of(Dendroid::Syntax::Terminal)
      expect(instance.symbols['PLUS']).to eq(instance.symbols[:PLUS])
      expect(instance.symbols[:PLUS].name).to eq(:PLUS)
      expect(instance.symbols[:STAR]).to be_kind_of(Dendroid::Syntax::Terminal)
      expect(instance.symbols['STAR']).to eq(instance.symbols[:STAR])
      expect(instance.symbols[:STAR].name).to eq(:STAR)
      expect(instance.symbols[:INTEGER]).to be_kind_of(Dendroid::Syntax::Terminal)
      expect(instance.symbols['INTEGER']).to eq(instance.symbols[:INTEGER])
      expect(instance.symbols[:INTEGER].name).to eq(:INTEGER)
      expect(instance.state).to eq(:declaring)
    end

    it 'builds production rules' do
      subject.rule('p' => 's')
      expect(subject.state).to eq(:building)

      # Undeclared symbols in production represent non-terminals
      expect(subject.symbols['p']).to be_kind_of(Dendroid::Syntax::NonTerminal)
      expect(subject.symbols['s']).to be_kind_of(Dendroid::Syntax::NonTerminal)

      expect(subject.rules.size).to eq(1)
      expect(subject.rules.first.to_s).to eq('p => s')
    end

    it 'builds a grammar' do
      subject.rule('p' => 's')
      subject.rule('s' => ['s PLUS m', 'm'])
      subject.rule('m' => ['m STAR t', 't'])
      subject.rule('t' => 'INTEGER')
      subject.grammar_complete!

      grm = subject.grammar
      expect(grm).to be_kind_of(Dendroid::Syntax::Grammar)
      (terms, nonterms) = grm.symbols.partition(&:terminal?)
      expect(terms.map(&:name)).to eq(%i[PLUS STAR INTEGER])
      expect(nonterms.map(&:name)).to eq(%i[p s m t])
      grammar_rules = [
        'p => s',
        's => s PLUS m | m',
        'm => m STAR t | t',
        't => INTEGER'
      ]
      expect(subject.rules.map(&:to_s)).to eq(grammar_rules)
    end

    it 'provides a simple DSL' do
      instance = described_class.new do
        declare_terminals('PLUS', 'STAR', 'INTEGER')
        rule('p' => 's')
        rule('s' => ['s PLUS m', 'm'])
        rule('m' => ['m STAR t', 't'])
        rule('t' => 'INTEGER')
      end

      grm = instance.grammar
      expect(grm).to be_kind_of(Dendroid::Syntax::Grammar)
      (terms, nonterms) = grm.symbols.partition(&:terminal?)
      expect(terms.map(&:name)).to eq(%i[PLUS STAR INTEGER])
      expect(nonterms.map(&:name)).to eq(%i[p s m t])
      grammar_rules = [
        'p => s',
        's => s PLUS m | m',
        'm => m STAR t | t',
        't => INTEGER'
      ]
      expect(instance.rules.map(&:to_s)).to eq(grammar_rules)
    end
  end # context
end # describe
