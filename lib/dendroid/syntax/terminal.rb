# frozen_string_literal: true

require_relative 'grm_symbol'

module Dendroid
  module Syntax
    # A terminal symbol is an elementary symbol of the language defined by the grammar.
    # More specifically, it represents a class of 'words'(or a token) of the language.
    class Terminal < GrmSymbol
      # Constructor.
      # aSymbolName [String] The name of the grammar symbol.
      def initialize(symbolName)
        super(symbolName)
        freeze
      end

      # Predicate method to check whether the symbol is a terminal symbol.
      # @return [TrueClass]
      def terminal?
        true
      end

      # Predicate method to check whether the symbol derives (matches)
      # the empty string. As a terminal symbol corresponds to an input token,
      # it is by definition non-nullable.
      # @return [FalseClass]
      def nullable?
        false
      end

      # Predicate method to check whether the symbol always matches
      # a non-empty sequence of terminal symbols.
      # @return [TrueClass]
      def productive?
        true
      end
    end # class
  end # module
end # module
