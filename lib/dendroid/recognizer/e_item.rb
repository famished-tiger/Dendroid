# frozen_string_literal: true

require 'forwardable'

module Dendroid
  module Recognizer
    # An Earley item is essentially a pair consisting of a dotted item and the rank of a token.
    # It helps to keep track the progress of an Earley recognizer.
    class EItem
      extend Forwardable

      # @return [Dendroid::GrmAnalysis::DottedItem]
      attr_reader :dotted_item

      # @return [Integer] the rank of the token that correspond to the start of the rule.
      attr_reader :origin

      def_delegators :@dotted_item, :completed?, :expecting?, :next_symbol, :pre_scan?

      # @param aDottedItem [Dendroid::GrmAnalysis::DottedItem]
      # @param origin [Integer]
      def initialize(aDottedItem, origin)
        @dotted_item = aDottedItem
        @origin = origin
      end

      # @return [Dendroid::Syntax::NonTerminal] the head of the production rule
      def lhs
        dotted_item.rule.lhs
      end

      # Equality test.
      # @return [Boolean] true iff dotted items and origins are equal
      def ==(other)
        return true if eql?(other)

        di = dotted_item
        (origin == other.origin) && (di == other.dotted_item)
      end

      # @return [String] the text representation of the Earley item
      def to_s
        "#{dotted_item} @ #{origin}"
      end
    end # class
  end # module
end # module
