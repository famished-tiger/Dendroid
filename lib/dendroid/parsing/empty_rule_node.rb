# frozen_string_literal: true

require_relative 'parse_node'

module Dendroid
  module Parsing
    class EmptyRuleNode < ParseNode
      attr_reader :rule
      attr_reader :alt_index

      def initialize(anEItem, rank)
        super(rank, rank)
        @rule = WeakRef.new(anEItem.dotted_item.rule)
        @alt_index = anEItem.dotted_item.alt_index
      end

      def to_s
        "_ #{super}"
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        aVisitor.visit_empty_rule_node(self)
      end
    end # class
  end # module
end # module
