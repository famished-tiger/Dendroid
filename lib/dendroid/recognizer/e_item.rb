# frozen_string_literal: true

require 'forwardable'
require 'weakref'

module Dendroid
  module Recognizer
    # An Earley item is essentially a pair consisting of a dotted item and the rank of a token.
    # It helps to keep track the progress of an Earley recognizer.
    class EItem
      extend Forwardable

      # (Weak) reference to the dotted item
      # @return [Dendroid::GrmAnalysis::DottedItem]
      attr_reader :dotted_item

      # @return [Integer] the rank of the token that correspond to the start of the rule.
      attr_reader :origin

      # TODO: :predictor, :completer, :scanner
      attr_accessor :algo

      # @return [Array<WeakRef>] predecessors sorted by decreasing origin value
      attr_accessor :predecessors

      def_delegators :@dotted_item, :completed?, :expecting?, :next_symbol, :pre_scan?, :position, :prev_symbol, :rule

      # @param aDottedItem [Dendroid::GrmAnalysis::DottedItem]
      # @param origin [Integer]
      def initialize(aDottedItem, origin)
        @dotted_item = WeakRef.new(aDottedItem)
        @origin = origin
        @predecessors = []
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

      alias inspect to_s

      def add_predecessor(pred)
        if predecessors.size > 1 && pred.origin < predecessors[0].origin
          predecessors.insert(2, WeakRef.new(pred))
        else
          predecessors.unshift(WeakRef.new(pred))
        end
      end
    end # class
  end # module
end # module
