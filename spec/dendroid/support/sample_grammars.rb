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
      rule('m' => ['m STAR t', 't'])
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
      map_verbatim2terminal({ '+' => :PLUS,
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
      rule('X' => %w[Y a])
    end

    builder.grammar
  end

  def grammar_l31
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      # Ambiguous arithmetical expression language
      # This language is compatible with tokenizer L1
      declare_terminals('PLUS', 'STAR', 'INTEGER')
      rule('p' => 's')
      rule('s' => ['s PLUS s', 's STAR s', 'INTEGER'])
    end

    builder.grammar
  end

  def grammar_l4
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      # (based on an example from Fisher and LeBlanc: "Crafting a Compiler")
      declare_terminals('plus', 'id')

      rule 'S' => 'E'
      rule 'E' => ['E plus E', 'id']
    end

    builder.grammar
  end

  def tokenizer_l4
    Dendroid::Utils::BaseTokenizer.new do
      map_verbatim2terminal({ '+' => :plus })

      scan_verbatim(['+'])
      scan_value(/[_A-Za-z][_A-Za-z0-9]*/, :id, ->(txt) { txt })
    end
  end

  def grammar_l5
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      # (based on example in N. Wirth "Compiler Construction" book, p. 6)
      declare_terminals('a', 'b', 'c')

      rule 'S' => 'A'
      rule 'A' => ['a A c', 'b']
    end

    builder.grammar
  end

  def tokenizer_l5
    Dendroid::Utils::BaseTokenizer.new do
      map_verbatim2terminal({ 'a' => :a, 'b' => :b, 'c' => :c })

      scan_verbatim(%w[a b c])
    end
  end

  def grammar_l6
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      # Grammar to illustrate the dangling else ambiguity
      # (based on grammar G5 from Douglas Thain "Introduction to Compiler and Language Design" book, p. 6)
      declare_terminals('if', 'then', 'else', 'E', 'other')

      rule 'P' => 'S'
      rule 'S' => ['if E then S', 'if E then S else S', 'other']
    end

    builder.grammar
  end

  def tokenizer_l6
    Dendroid::Utils::BaseTokenizer.new do
      map_verbatim2terminal({ 'if' => :if,
                              'then' => :then,
                              'else' => :else,
                              'E' => :E,
                              'other' => :other })

      scan_verbatim(%w[if then else E other])
    end
  end

  def grammar_l7
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      # (based on grammar G1 from paper Elizabeth Scott, Adrian Johnstone "Recognition
      # is not parsing SPPF-style parsing from cubic recognisers")
      declare_terminals('a')

      rule 'S' => ['S T', 'a']
      rule 'B' => ''
      rule 'T' => ['a B', 'a']
    end

    builder.grammar
  end

  def tokenizer_l7
    Dendroid::Utils::BaseTokenizer.new do
      map_verbatim2terminal({ 'a' => :a })

      scan_verbatim(['a'])
    end
  end

  def grammar_l8
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      # (based on grammar G2 from paper Masaru Tomita "An Efficient Context-Free Parsing Algorithm
      #   for Natural Languages")
      declare_terminals('x')

      rule 'S' => ['S S', 'x']
    end

    builder.grammar
  end

  def tokenizer_l8
    Dendroid::Utils::BaseTokenizer.new do
      map_verbatim2terminal({ 'x' => :x })

      scan_verbatim(['x'])
    end
  end

  def grammar_l9
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      # (based on "infinite ambiguity" grammar from paper Masaru Tomita "An Efficient Context-Free Parsing Algorithm
      #   for Natural Languages")
      declare_terminals('x')

      rule 'S' => ['S S', '', 'x']
    end

    builder.grammar
  end

  def tokenizer_l9
    Dendroid::Utils::BaseTokenizer.new do
      map_verbatim2terminal({ 'x' => :x })

      scan_verbatim(['x'])
    end
  end

  def grammar_l10
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      declare_terminals('a')

      rule 'A' => ['A a', '']
    end

    builder.grammar
  end

  def tokenizer_l10
    Dendroid::Utils::BaseTokenizer.new do
      map_verbatim2terminal({ 'a' => :a })

      scan_verbatim(['a'])
    end
  end

  def grammar_l11
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      declare_terminals('a')

      rule 'A' => ['a A', '']
    end

    builder.grammar
  end

  def tokenizer_l11
    Dendroid::Utils::BaseTokenizer.new do
      map_verbatim2terminal({ 'a' => :a })

      scan_verbatim(['a'])
    end
  end

  def grammar_l12
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      # (based on grammar Example 3 from paper Elizabeth Scott "SPPF-Style Parsing
      #   from Earley Recognisers")
      # Grammar with hidden left recursion and a cycle
      declare_terminals('a', 'b')

      rule 'S' => ['A T', 'a T']
      # rule 'S' => 'a T'
      rule 'A' => ['a', 'B A']
      # rule 'A' => 'B A'
      rule 'B' => ''
      rule 'T' => 'b b b'
    end

    builder.grammar
  end

  def tokenizer_l12
    Dendroid::Utils::BaseTokenizer.new do
      map_verbatim2terminal({ 'a' => :a, 'b' => :b })

      scan_verbatim(%w[a b])
    end
  end

  def grammar_l13
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      # Grammar based on example RR from Sylvie Billot, Bernard Lang "The Structure of Shared Forests
      #   in Ambiguous Parsing"
      declare_terminals('x')

      rule 'A' => ['x A', 'x']
      # rule 'A' => 'x'
    end

    builder.grammar
  end

  def tokenizer_l13
    Dendroid::Utils::BaseTokenizer.new do
      map_verbatim2terminal({ 'x' => :x })

      scan_verbatim(['x'])
    end
  end

  def grammar_l14
    builder = Dendroid::GrmDSL::BaseGrmBuilder.new do
      # Grammar 4: A grammar with nullable nonterminal
      # based on example from "Parsing Techniques" book, p. 216
      # (D. Grune, C. Jabobs)
      declare_terminals('a', 'star', 'slash')

      rule 'S' => 'E'
      rule 'E' => ['E Q F', 'F']
      rule 'F' => 'a'
      rule 'Q' => ['star', 'slash', '']
    end

    builder.grammar
  end

  def tokenizer_l14
    Dendroid::Utils::BaseTokenizer.new do
      map_verbatim2terminal({ 'a' => :a, '*' => :star, '/' => :slash })

      scan_verbatim(['a', '*', '/'])
    end
  end
end # module
