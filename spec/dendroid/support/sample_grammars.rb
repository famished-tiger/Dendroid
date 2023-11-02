# frozen_string_literal: true

require_relative '../../../lib/dendroid/grm_dsl/base_grm_builder'
require_relative '../../../lib/dendroid/utils/base_tokenizer'

module SampleGrammars
  def grammar_l1
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      # Grammar inspired from Wikipedia entry on Earley parsing
      declare_terminals('PLUS', 'STAR', 'INTEGER')
      rule('p' => 's')
      rule('s' => ['s PLUS m', 'm'])
      # rule('s' => 'm')
      rule('m' => ['m STAR t', 't'])
      # rule('m' => 't')
      rule('t' => 'INTEGER')
    end

    builder.grammar
  end

  def tokenizer_l1
    Dendroid::Utils::BaseTokenizer.new do
      map_verbatim2terminal({ '+' => :PLUS, '*' => :STAR })

      scan_verbatim(['+', '*'])
      scan_value(/\d+/, :INTEGER, ->(txt) { txt.to_i })
    end
  end


  def grammar_l2
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      # Grammar inspired from Loup Vaillant's example
      # https://loup-vaillant.fr/tutorials/earley-parsing/recogniser
      declare_terminals('PLUS', 'MINUS',  'STAR', 'SLASH')
      declare_terminals('LPAREN', 'RPAREN', 'NUMBER')

      rule('p' => 'sum')
      rule('sum' => ['sum PLUS product', 'sum MINUS product', 'product'])
      rule('product' => ['product STAR factor', 'product SLASH factor', 'factor'])
      rule('factor' => ['LPAREN sum RPAREN', 'NUMBER'])
    end

    builder.grammar
  end

  def tokenizer_l2
    Dendroid::Utils::BaseTokenizer.new do
      map_verbatim2terminal({
                              '+' => :PLUS,
                              '-' => :MINUS,
                              '*' => :STAR,
                              '/' => :SLASH,
                              '(' => :LPAREN,
                              ')' => :RPAREN })

      scan_verbatim(['+', '-', '*', '/', '(', ')'])
      scan_value(/\d+/, :NUMBER, ->(txt) { txt.to_i })
    end
  end

  def grammar_l3
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      # Grammar inspired from Andrew Appel's example
      # Modern Compiler Implementation in Java
      declare_terminals('a', 'c', 'd')

      rule('Z' => ['d', 'X Y Z'])
      rule('Y' => ['', 'c'])
      rule('X' => ['Y', 'a'])
    end

    builder.grammar
  end
end # module
