# frozen_string_literal: true

require_relative 'rule'

module Dendroid
  module Syntax
    # A specialization of the Rule class.
    # A production is a rule with a single rhs
    class Production < Rule
      # @return [Dendroid::Syntax::SymbolSeq]
      attr_reader :body

      # Create a Production instance.
      # @param lhs [Dendroid::Syntax::NonTerminal] The left-hand side of the rule.
      # @param rhs [Dendroid::Syntax::SymbolSeq] the sequence of symbols on rhs.
      def initialize(lhs, rhs)
        super(lhs)
        @body = valid_body(rhs)
      end

      # Predicate method to check whether the rule body (its rhs) is empty.
      # @return [Boolean]
      def empty?
        body.empty?
      end

      # Predicate method to check whether the rule has alternatives
      # @return [FalseClass]
      def choice?
        false
      end

      # Predicate method to check whether the production rule body is productive.
      # It is productive when it is empty or all of its rhs members are productive too.
      # @return [Boolean, NilClass]
      def productive?
        if @productive.nil?
          if body.productive?
            self.productive = true
          else
            nil
          end
        else
          @productive
        end
      end

      # Mark the production rule as non-productive.
      def non_productive
        self.productive = false
      end

      # Return the text representation of the production rule
      # @return [String]
      def to_s
        "#{head} => #{body}"
      end

      # Equality operator
      # Two production rules are equal when their head and rhs are equal.
      # @return [Boolean]
      def ==(other)
        return true if equal?(other)

        (head == other.head) && (body == other.body)
      end

      # Returns an array with the symbol sequence of its rhs
      # @return [Array<Dendroid::Syntax::SymbolSeq>]
      def rhs
        [body]
      end

      private

      def valid_body(rhs)
        raise StandardError unless rhs.is_a?(SymbolSeq)

        if rhs.size == 1 && lhs == rhs.first
          # Forbid cyclic rules (e.g. A => A)
          raise StandardError.new, "Cyclic rule of the kind #{lhs} => #{lhs} is not allowed."
        end

        rhs
      end

      def productive=(val)
        @productive = val
        lhs.productive = val
      end
    end # class
  end # module
end # module
