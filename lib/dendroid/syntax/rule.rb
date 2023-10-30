# frozen_string_literal: true

module Dendroid
  module Syntax
    # In a context-free grammar, a rule has its left-hand side (LHS)
    # that consists solely of one non-terminal symbol.
    # and the right-hand side (RHS) consists of one or more sequence of symbols.
    # The symbols in RHS can be either terminal or non-terminal symbols.
    # The rule stipulates that the LHS is equivalent to the RHS,
    # in other words every occurrence of the LHS can be substituted to
    # corresponding RHS.
    class Rule
      # @return [Dendroid::Syntax::NonTerminal] The left-hand side of the rule.
      attr_reader :head
      alias lhs head

      # Create a Rule instance.
      # @param lhs [Dendroid::Syntax::NonTerminal] The left-hand side of the rule.
      def initialize(lhs)
        @head = valid_head(lhs)
      end

      # Return the text representation of the rule
      # @return [String]
      def to_s
        head.to_s
      end

      # The set of all grammar symbols that occur in the rhs.
      # @return [Array<Dendroid::Syntax::GrmSymbol>]
      def rhs_symbols
        symbols = rhs.reduce([]) do |result, alt|
          result.concat(alt.members)
        end
        symbols.uniq
      end

      # The set of all non-terminal symbols that occur in the rhs.
      # @return [Array<Dendroid::Syntax::NonTerminal>]
      def nonterminals
        rhs_symbols.reject(&:terminal?)
      end

      # The set of all terminal symbols that occur in the rhs.
      # @return [Array<Dendroid::Syntax::Terminal>]
      def terminals
        rhs_symbols.select(&:terminal?)
      end

      protected

      def valid_sequence(rhs)
        raise StandardError, "Expecting a SymbolSeq, found a #{rhs.class} instead." unless rhs.is_a?(SymbolSeq)

        if rhs.size == 1 && lhs == rhs.first
          # Forbid cyclic rules (e.g. A => A)
          raise StandardError.new, "Cyclic rules of the kind #{lhs} => #{lhs} are not allowed."
        end

        rhs
      end

      private

      def valid_head(lhs)
        if lhs.terminal?
          err_msg = "Terminal symbol '#{lhs}' may not be on left-side of a rule."
          raise StandardError, err_msg
        end

        lhs
      end
    end # class
  end # module
end # module
