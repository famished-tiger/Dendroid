# frozen_string_literal: true

require 'weakref'

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
      # (Weak) reference to the production rule
      # @return [Dendroid::Syntax::Production]
      attr_reader :rule

      # @return [Integer] the dot position
      attr_reader :position

      # @return [Integer] the alternative number
      attr_reader :alt_index

      # Constructor.
      # @param aChoice [Dendroid::Syntax::Rule]
      # @param aPosition [Integer] Position of the dot in rhs of production.
      # @param index [Integer] the rank of the alternative at hand
      def initialize(aChoice, aPosition, index)
        @alt_index = index
        @rule = WeakRef.new(aChoice)
        @position = valid_position(aPosition)
      end

      # Return a String representation of the alternative item.
      # @return [String]
      def to_s
        rhs_names = rule.alternatives[alt_index].members.map(&:to_s)
        dotted_rhs = rhs_names.insert(position, '.')
        "#{rule.head} => #{dotted_rhs.join(' ')}"
      end

      alias inspect to_s

      # Indicate whether the rhs of the alternative is empty
      # @return [Boolean]
      def empty?
        rule.alternatives[alt_index].empty?
      end

      # Indicate whether the dot is at the start of rhs
      # @return [Boolean]
      def initial_pos?
        position.zero? || empty?
      end

      # Indicate the dot isn't at start nor at end position
      # @return [Boolean]
      def intermediate_pos?
        return false if empty? || position.zero?

        position < rule.alternatives[alt_index].size
      end

      # Indicate whether the dot is at the start of rhs
      # @return [Boolean]
      def final_pos?
        empty? || position == rule.alternatives[alt_index].size
      end

      alias completed? final_pos?

      # Terminology inspired from Luger's book
      # @return [Symbol] one of: :initial, :initial_and_completed, :partial, :completed
      def state
        return :initial_and_completed if empty?
        return :initial if position.zero?

        position == rule.alternatives[alt_index].size ? :completed : :partial
      end

      # Return the symbol right after the dot (if any)
      # @return [Dendroid::Syntax::GrmSymbol, NilClass]
      def next_symbol
        return nil if empty? || completed?

        rule.alternatives[alt_index].members[position]
      end

      # Return the symbol right before the dot (if any)
      # @return [Dendroid::Syntax::GrmSymbol, NilClass]
      def prev_symbol
        return nil if empty? || position.zero?

        rule.alternatives[alt_index].members[position - 1]
      end

      # Check whether the given symbol is the same as after the dot.
      # @param aSymbol [Dendroid::Syntax::GrmSymbol]
      # @return [Boolean]
      def expecting?(aSymbol)
        actual = next_symbol
        return false if actual.nil?

        actual == aSymbol
      end

      # Check whether the dotted item is a shift item.
      # In other words, it expects a terminal to be the next symbol
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

        (position == other.position) && rule.eql?(other.rule) && (alt_index == other.alt_index)
      end

      private

      def valid_position(aPosition)
        raise StandardError if aPosition.negative? || aPosition > rule.alternatives[alt_index].size

        aPosition
      end
    end # class
  end # module
end # module
