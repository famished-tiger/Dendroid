# frozen_string_literal: true

require 'forwardable'
require_relative 'grm_symbol'

module Dendroid
  module Syntax
    # A sequence of grammar symbols. This class is used to represent
    # members of right-hand side of production rules
    class SymbolSeq
      extend Forwardable

      # @return [Array<Dendroid::Syntax::GrmSymbol>] The sequence of symbols
      attr_reader :members

      def_delegators(:@members, :empty?, :first, :map, :size)

      # Create a sequence of grammar symbols (as in right-hand side of
      # a production rule).
      # @param symbols [Array<Dendroid::Syntax::GrmSymbol>] An array of symbols.
      def initialize(symbols)
        @members = symbols
      end

      # @return [String] A text representation of the symbol sequence
      def to_s
        members.join(' ')
      end

      # Retrieve all the non-terminal symbols in the sequence.
      # @return [Array<Dendroid::Syntax::NonTerminal>] array of non-terminals.
      def nonterminals
        members.reject(&:terminal?)
      end

      # Retrieve all the terminal symbols in the sequence.
      # @return [Array<Dendroid::Syntax::Terminal>] array of terminals
      def terminals
        members.select(&:terminal?)
      end

      # Predicate method to check whether the sequence always derives (matches)
      # a non-empty sequence of terminal symbols.
      # @return [Boolean]
      def productive?
        empty? || members.all?(&:productive?)
      end

      # Equality operator.
      # @param other [Dendroid::Syntax::SymbolSeq]
      # @return [Boolean] true when members are equal to the ones from `other`
      def ==(other)
        members == other.members
      end

      private

      def valid_members(symbols)
        raise StandardError unless symbols.all? { |symb| symb.is_a?(GrmSymbol) }
      end
    end # class
  end # module
end # module
