# frozen_string_literal: true

require_relative 'grm_symbol'

module Dendroid
  module Syntax
    # A non-terminal symbol (sometimes called a syntactic variable) represents
    # a composition of terminal or non-terminal symbols
    class NonTerminal < GrmSymbol
      # @return [Boolean] true if symbol can derive the null token
      attr_accessor :nullable

      # @return [Boolean] true iff the symbol always matches a non-empty
      #   sequence of terminal symbols
      attr_accessor :productive

      # Predicate method to check whether the symbol is a terminal symbol.
      # @return [FalseClass]
      def terminal?
        false
      end

      # Predicate method to check whether the symbol can derive (match)
      # the null token.
      # @return [Boolean]
      def nullable?
        @nullable
      end

      # Predicate method to check whether the symbol always matches
      # a non-empty sequence of terminal symbols.
      # @return [Boolean]
      def productive?
        @productive
      end
    end # class
  end # module
end # module
