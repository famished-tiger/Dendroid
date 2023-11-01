# frozen_string_literal: true

require_relative 'dotted_item'

module Dendroid
  module GrmAnalysis
    # A specialization of DottedItem specific for Choice (rule)
    class AlternativeItem < DottedItem
      # @return [Integer] the alternative number
      attr_reader :alt_index

      # Constructor.
      # @param aChoice [Dendroid::Syntax::Choice]
      # @param aPosition [Integer] Position of the dot in rhs of production.
      # @param index [Integer] the rank of the alternative at hand
      def initialize(aChoice, aPosition, index)
        @alt_index = index
        super(aChoice, aPosition)
      end

      # Return a String representation of the alternative item.
      # @return [String]
      def to_s
        rhs_names = rule.alternatives[alt_index].members.map(&:to_s)
        dotted_rhs = rhs_names.insert(position, '.')
        "#{rule.head} => #{dotted_rhs.join(' ')}"
      end

      # Indicate whether the rhs of the alternative is empty
      # @return [Boolean]
      def empty?
        rule.alternatives[alt_index].empty?
      end

      # Indicate whether the dot is at the start of rhs
      # @return [Boolean]
      def final_pos?
        empty? || position == rule.alternatives[alt_index].size
      end

      alias completed? final_pos?

      # Return the symbol right after the dot (if any)
      # @return [Dendroid::Syntax::GrmSymbol, NilClass]
      def next_symbol
        return nil if empty? || completed?

        rule.alternatives[alt_index].members[position]
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
        raise Exception if aPosition < 0 || aPosition > rule.alternatives[alt_index].size

        aPosition
      end
    end # class
  end # module
end # module

