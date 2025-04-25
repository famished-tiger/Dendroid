# frozen_string_literal: true

require 'forwardable'
module Dendroid
  module Recognizer


    # An Earley item is essentially a pair consisting of a dotted item and the rank of a token.
    # It helps to keep track the progress of an Earley recognizer.
    class EItem
      # Mix-in module used to forward some method calls to the related dotted item.
      extend Forwardable

      # (Weak) reference to the dotted item
      # @return [Dendroid::GrmAnalysis::DottedItem]
      attr_reader :dotted_item

      # @return [Integer] the rank of the token that correspond to the start of the rule.
      attr_reader :origin

      # Specifies the algorithm with which this entry can be derived from its predecessor(s).
      # @return [Symbol] of one: :predictor, :completer, :scanner
      attr_accessor :algo

      # @return [Array<EItem>] predecessors sorted by decreasing origin value
      attr_accessor :predecessors

      def_delegators :@dotted_item, :completed?, :expecting?, :initial_pos?, :next_symbol, :pre_scan?, :position, :prev_symbol, :rule

      # @param aDottedItem [Dendroid::GrmAnalysis::DottedItem]
      # @param origin [Integer]
      def initialize(aDottedItem, origin)
        @dotted_item = aDottedItem
        @origin = origin
        @predecessors = []
      end

      # @return [Dendroid::Syntax::NonTerminal] the head of the production rule
      def lhs
        dotted_item.rule.lhs
      end

      # @return [Dendroid::Syntax::SymbolSeq] the applicable right-hand side of the rule
      def rhs
        dotted_item.rule.rhs[dotted_item.alt_index]
      end

      # Equality test.
      # @return [Boolean] true iff dotted items and origins are equal
      def ==(other)
        return true if eql?(other)

        di = dotted_item
        (origin == other.origin) && (di == other.dotted_item)
      end

      def rule
        dotted_item.rule
      end

      # @return [String] the text representation of the Earley item
      def to_s
        "#{dotted_item} @ #{origin}"
      end

      alias inspect to_s

      def add_predecessor(pred)
        if predecessors.size > 1 && pred.origin < predecessors[0].origin
          predecessors.insert(2, pred)
        else
          predecessors.unshift(pred)
        end
      end
    end # class
  end # module
end # module
