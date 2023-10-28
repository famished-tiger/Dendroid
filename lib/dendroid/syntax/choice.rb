# frozen_string_literal: true

require_relative 'rule'

module Dendroid
  module Syntax
    # A specialization of the Rule class.
    # A choice is a rule with multiple rhs
    class Choice < Rule
      # @return [Array<Dendroid::Syntax::SymbolSeq>]
      attr_reader :alternatives

      # Create a Choice instance.
      # @param lhs [Dendroid::Syntax::NonTerminal] The left-hand side of the rule.
      # @param alt [Array<Dendroid::Syntax::SymbolSeq>] the alternatives (each as a sequence of symbols).
      def initialize(lhs, alt)
        super(lhs)
        @alternatives = valid_alternatives(alt)
      end

      # Predicate method to check whether the rule has alternatives
      # @return [TrueClass]
      def choice?
        true
      end

      # Return the text representation of the choice
      # @return [String]
      def to_s
        "#{head} => #{alternatives.join(' | ')}"
      end

      # Predicate method to check whether the choice rule body is productive.
      # It is productive when at least of its alternative is productive.
      # @return [Boolean]
      def productive?
        productive_alts = alternatives.select(&:productive?)
        return false if productive_alts.empty?

        @productive = Set.new(productive_alts)
        head.productive = true
      end

      # Predicate method to check whether the rule has at least one empty alternative.
      # @return [Boolean]
      def empty?
        alternatives.any?(&:empty?)
      end

      # Returns an array with the symbol sequence of its alternatives
      # @return [Array<Dendroid::Syntax::SymbolSeq>]
      def rhs
        alternatives
      end

      # Equality operator
      # Two production rules are equal when their head and alternatives are equal.
      # @return [Boolean]
      def ==(other)
        return true if equal?(other)
        return false if other.is_a?(Production)

        (head == other.head) && (alternatives == other.alternatives)
      end

      private

      def valid_alternatives(alt)
        if alt.size < 2
          # A choice must have at least two alternatives
          raise StandardError.new, "The choice for #{lhs} must have at least two alternatives."
        end

        cyclic = alt.find { |a| a.size == 1 && lhs == a.first }
        if cyclic
          # Forbid cyclic rules (e.g. A => A)
          raise StandardError.new, "Cyclic rule of the kind #{lhs} => #{lhs} is not allowed."
        end

        alt
      end
    end # class
  end # module
end # module
