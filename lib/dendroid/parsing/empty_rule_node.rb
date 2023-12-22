# frozen_string_literal: true

require 'weakref'
require_relative 'parse_node'

module Dendroid
  module Parsing
    # A parse tree/forest node that is related to a production rule with an empty
    # RHS (right-hand side).
    class EmptyRuleNode < ParseNode
      # @return [WeakRef<Dendroid::Syntax::Rule>] Grammar rule
      attr_reader :rule

      # @return [Integer] Index of the rule alternative.
      attr_reader :alt_index

      # @param anEItem [Dendroid::Recognizer::EItem] An entry from the chart.
      # @param rank [Integer] rank of the last input token matched by this node
      def initialize(anEItem, rank)
        super(rank, rank)
        @rule = WeakRef.new(anEItem.dotted_item.rule)
        @alt_index = anEItem.dotted_item.alt_index
      end

      # Return a String representation of itself
      # @return [String] text representation of itself
      def to_s
        "_ #{range_to_s}"
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        aVisitor.visit_empty_rule_node(self)
      end
    end # class
  end # module
end # module
