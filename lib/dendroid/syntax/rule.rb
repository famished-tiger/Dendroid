# frozen_string_literal: true

module Dendroid
  module Syntax
    # A specialization of the Rule class.
    # A choice is a rule with multiple rhs
    class Rule
      # @return [Dendroid::Syntax::NonTerminal] The left-hand side of the rule.
      attr_reader :head
      alias lhs head

      # @return [Array<Dendroid::Syntax::SymbolSeq>]
      attr_reader :alternatives

      # Create a Choice instance.
      # @param theLhs [Dendroid::Syntax::NonTerminal] The left-hand side of the rule.
      # @param alt [Array<Dendroid::Syntax::SymbolSeq>] the alternatives (each as a sequence of symbols).
      def initialize(theLhs, alt)
        @head = valid_head(theLhs)
        @alternatives = valid_alternatives(alt)
      end

      # Return the text representation of the choice
      # @return [String]
      def to_s
        "#{head} => #{alternatives.join(' | ')}"
      end

      # Predicate method to check whether the choice rule body is productive.
      # It is productive when at least one of its alternative is productive.
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

        (head == other.head) && (alternatives == other.alternatives)
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

      def valid_alternatives(alt)
        raise StandardError, "Expecting an Array, found a #{rhs.class} instead." unless alt.is_a?(Array)

        if alt.size.zero?
          # A choice must have at least two alternatives
          raise StandardError, "The choice for `#{head}` must have at least one alternative."
        end

        # Verify that each array element is a valid symbol sequence
        alt.each { |elem| valid_sequence(elem) }

        # Fail when duplicate rhs found
        alt_texts = alt.map(&:to_s)
        no_duplicate = alt_texts.uniq
        if alt_texts.size > no_duplicate.size
          alt_texts.each_with_index do |str, i|
            next if str == no_duplicate[i]

            err_msg = "Duplicate alternatives: #{head} => #{alt_texts[i]}"
            raise StandardError, err_msg
          end
        end

        alt
      end
    end # class
  end # module
end # module
