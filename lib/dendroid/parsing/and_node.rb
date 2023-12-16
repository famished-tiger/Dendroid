# frozen_string_literal: true

require_relative 'composite_parse_node'

module Dendroid
  module Parsing
    class ANDNode < CompositeParseNode
      attr_reader :rule
      attr_reader :alt_index

      def initialize(anEItem, rank)
        @rule = WeakRef.new(anEItem.dotted_item.rule)
        @alt_index = anEItem.dotted_item.alt_index
        upper_bound = rank
        super(anEItem.origin, upper_bound, rule.rhs[alt_index].size)
      end

      def add_child(child_node, index)
        if children[index].nil? # Is slot available?
          super(child_node, index)
        else
          raise StandardError
        end
      end

      def match(anEItem)
        return false if range[0] != anEItem.origin

        dotted = anEItem.dotted_item
        same_rule = (rule.lhs == dotted.rule.lhs) && (alt_index == dotted.alt_index)
        return false unless same_rule

        dotted.initial_pos? ? true : partial?
      end

      def expecting?(symbol, position)
        symb_seq = rule.rhs[alt_index]
        symb_seq[position] == symbol
      end

      def partial?
        children.any?(&:nil?)
      end

      def to_s
        "#{rule.lhs} => #{rule.rhs[alt_index]} #{range}"
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        aVisitor.visit_and_node(self)
      end
    end # class
  end # module
end # module