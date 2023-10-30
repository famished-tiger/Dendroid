# frozen_string_literal: true

module Dendroid
  module GrmAnalysis
    # For a given production rule, a dotted item represents a recognition state.
    # The dot partitions the rhs of the rule in two parts:
    # a) the left part consists of the symbols in the rhs that are matched
    # by the input tokens.
    # b) The right part consists of symbols that are predicted to match the
    # input tokens.
    # The terminology stems from the traditional way to visualize the partition
    # by using a fat dot character as a separator between the left and right
    # parts.
    # An item with the dot at the beginning (i.e. before any rhs symbol)
    #  is called a predicted item.
    # An item with the dot at the end (i.e. after all rhs symbols)
    #  is called a reduce item.
    # An item with a dot in front of a terminal is called a shift item.
    # An item with the dot not at the beginning is sometimes referred to as a kernel item
    class DottedItem
      # Reference to the production rule
      # @return [Dendroid::Syntax::Production]
      attr_reader :rule

      # @return [Integer] the dot position
      attr_reader :position

      # Constructor.
      # @param aRule [Dendroid::Syntax::Rule]
      # @param aPosition [Integer] Position of the dot in rhs of production.
      def initialize(aRule, aPosition)
        @rule = aRule
        @position = valid_position(aPosition)
      end

      # Return a String representation of the dotted item.
      # @return [String]
      def to_s
        rhs_names = rule.body.map(&:to_s)
        dotted_rhs = rhs_names.insert(position, '.')
        "#{rule.head} => #{dotted_rhs.join(' ')}"
      end

      # Indicate whether the rhs of the rule is empty
      # @return [Boolean]
      def empty?
        rule.empty?
      end

      # Terminology inspired from Luger's book
      # @return [Symbol] one of: :initial, :initial_and_completed, :partial, :completed
      def state
        return :initial_and_completed if empty?
        return :initial if position.zero?

        position == rule.body.size ? :completed : :partial
      end

      # Indicate whether the dot is at the start of rhs
      # @return [Boolean]
      def initial_pos?
        position.zero? || empty?
      end

      # Indicate whether the dot is at the end of rhs
      # @return [Boolean]
      def final_pos?
        empty? || position == rule.body.size
      end

      alias completed? final_pos?

      # Indicate the dot isn't at start nor at end position
      # @return [Boolean]
      def intermediate_pos?
        return false if empty? || position.zero?

        position < rule.body.size
      end

      # Return the symbol right after the dot (if any)
      # @return [Dendroid::Syntax::GrmSymbol, NilClass]
      def next_symbol
        return nil if empty? || completed?

        rule.body[position]
      end

      # Check whether the given symbol is the same as after the dot.
      # @param [Dendroid::Syntax::GrmSymbol]
      # @return [Boolean]
      def expecting?(aSymbol)
        actual = next_symbol
        return false if actual.nil?

        actual == aSymbol
      end

      # Check whether the dotted item is a shift item.
      # In other words, it expects a terminal to be next symbol
      # @return [Boolean]
      def pre_scan?
        next_symbol&.terminal?
      end

      # Test for equality with another dotted item.
      # Two dotted items are equal if they refer to the same rule and
      # have both the same rhs and dot positions.
      # @return [Boolean]
      def ==(other)
        return true if eql?(other)

        (position == other.position) && rule.eql?(other.rule)
      end

      private

      def valid_position(aPosition)
        raise StandardError if aPosition.negative? || aPosition > rule.body.size

        aPosition
      end
    end # class
  end # module
end # module
