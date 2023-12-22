# frozen_string_literal: true

require_relative 'token'

module Dendroid
  module Lexical
    # A literal (value) is a token that represents a data value in the parsed
    # language. For instance, in Ruby data values such as strings, numbers,
    # regular expression,... can appear directly in the source code as text.
    # These are examples of literal values. One responsibility of a tokenizer/lexer is
    # to convert the text representation into a corresponding value in a
    # convenient format for the interpreter/compiler.
    class Literal < Token
      # @return [Object] The value expressed in one of the target datatype.
      attr_reader :value

      # Constructor.
      # @param original [String] the piece of text from input
      # @param pos [Dendroid::Lexical::TokenPosition] line, column position of token
      # @param symbol [Dendroid::Syntax::Terminal, String]
      # @param aValue [Object] value of the token in internal representation
      def initialize(original, pos, symbol, aValue)
        super(original, pos, symbol)
        @value = aValue
      end

      # @return [Boolean] true if the token is a literal (has a value associated with is)
      def literal?
        true
      end
    end # class
  end # module
end # module
