# frozen_string_literal: true

require_relative 'composite_parse_node'

module Dendroid
  module Parsing
    # A composite parse node that matches the sequence of grammar symbols from
    # a right-hand side of a rule to a range of input tokens. The child nodes
    # correspond to the grammar symbols in the RHS of the rule.
    class AndNode < CompositeParseNode
      # @return [WeakRef<Dendroid::Syntax::Rule>] Grammar rule
      attr_reader :rule

      # @return [Integer] Index of the rule alternative.
      attr_reader :alt_index

      # @param anEItem [Dendroid::Recognizer::EItem] An entry from the chart.
      # @param rank [Integer] rank of the last input token matched by this node
      def initialize(anEItem, rank)
        @rule = WeakRef.new(anEItem.dotted_item.rule)
        @alt_index = anEItem.dotted_item.alt_index
        upper_bound = rank
        super(anEItem.origin, upper_bound, rule.rhs[alt_index].size)
      end

      # Add a child a given available position.
      # @param child_node [Dendroid::Parsing::ParseNode] Node to add as a child
      # @param index [Integer] position of the child node in the `children` array
      def add_child(child_node, index)
        raise StandardError unless children[index].nil? # Is slot available?

        super(child_node, index)
      end

      # Is the given chart entry matching this node?
      # The chart entry matches this node if:
      #   - its origin equals to the start of the range; and,
      #   - both rules are the same; and,
      # @return [Boolean] true if the entry corresponds to this node.
      def match(anEItem)
        return false if range.begin != anEItem.origin

        dotted = anEItem.dotted_item
        same_rule = (rule.lhs == dotted.rule.lhs) && (alt_index == dotted.alt_index)
        return false unless same_rule

        dotted.initial_pos? ? true : partial?
      end

      # Is this node expecting at given RHS index, the given symbol?
      # @param symbol [Dendroid::Syntax::GrmSymbol]
      # @param position [Integer] index of given member in RHS of the rule
      def expecting?(symbol, position)
        symb_seq = rule.rhs[alt_index]
        symb_seq[position] == symbol
      end

      # @return [Boolean] true if at least one of the children slots is free.
      def partial?
        children.any?(&:nil?)
      end

      # Return a String representation of itself
      # @return [String] text representation of itself
      def to_s
        "#{rule.lhs} => #{rule.rhs[alt_index]} #{range_to_s}"
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        aVisitor.visit_and_node(self)
      end
    end # class
  end # module
end # module
