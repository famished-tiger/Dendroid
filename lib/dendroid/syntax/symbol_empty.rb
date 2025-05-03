# frozen_string_literal: true

require 'singleton'
require_relative 'grm_symbol'

module Dendroid
  module Syntax
    # A grammar symbol that represents an empty string allowed by the grammar.
    class SymbolEmpty < GrmSymbol
      include Singleton

      # Predicate method to check whether the symbol is a terminal symbol.
      # @return [TrueClass]
      def terminal?
        true
      end

      # Predicate method to check whether the symbol derives (matches)
      # the empty string. A null symbol corresponds to zero input token,
      # it is by definition nullable.
      # @return [TrueClass]
      def nullable?
        true
      end
			
			alias void? nullable?

      # Predicate method to check whether the symbol always matches
      # a non-empty sequence of terminal symbols.
      # @return [FalseClass]
      def productive?
        false
      end

      private

      # Constructor.
      def initialize
        super('epsilon')
        freeze
      end
    end # class
  end # module
end # module
