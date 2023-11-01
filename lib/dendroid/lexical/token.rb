# frozen_string_literal: true

module Dendroid
  # This module contains the core classes needed for lexical analysis.
  # The lexical analysis (tokenization) aims to transform the input stream of characters
  # into a sequence of tokens.
  module Lexical
    # A (lexical) token is an object created by a tokenizer (lexer)
    # and passed to the parser. Such token object is created when a lexer
    # detects that a sequence of characters(a lexeme) from the input stream
    # is an instance of a terminal grammar symbol.
    # Say, that in a particular language, the lexeme 'foo' is an occurrence
    # of the terminal symbol IDENTIFIER. Then the lexer will return a Token
    # object that states the fact that 'foo' is indeed an IDENTIFIER. Basically,
    # a Token is a pair (lexeme, terminal): it asserts that a given piece of text
    # is an instance of given terminal symbol.
    class Token
      # The sequence of character(s) from the input stream that is an occurrence
      # of the related terminal symbol.
      # @return [String] Input substring that is an instance of the terminal.
      attr_reader :source

      # @return [TokenPosition] The position -in "editor" coordinates- of the text in the source file.
      attr_reader :position

      # @return [String] The name of terminal symbol matching the text.
      attr :terminal

      # Constructor.
      # @param original [String] the piece of text from input
      # @param pos [Dendroid::Lexical::TokenPosition] position of the token in source file
      # @param symbol [Dendroid::Syntax::Terminal, String]
      #   The terminal symbol corresponding to the matching text.
      def initialize(original, pos, symbol)
        @source = original.dup
        @position = pos
        @terminal = symbol
      end

      # @return [String] The text representation of the token position
      def pos_to_s
        position.to_s
      end
    end # class
  end # module
end # module
