# frozen_string_literal: true

require_relative 'composite_parse_node'

module Dendroid
  module Parsing
    # A composite parse node that embodies multiple syntactical derivations of a right-hand side of a rule
    # to a range of input tokens. Each child node corresponds to a distinct derivation.
    class OrNode < CompositeParseNode
      # @return [Dendroid::Syntax::NonTerminal] The non-terminal symbol at LHS of rule
      attr_reader :symbol

      # @param sym [Dendroid::Syntax::NonTerminal]
      # @param lower [Integer] lowest token rank matching start of the rule
      # @param upper [Integer] largest token rank matching start of the rule
      # @param arity [Integer] Number of derivations of the given rule
      def initialize(sym, lower, upper, arity)
        @symbol = sym
        super(lower, upper, arity)
      end

      # Add a child node as root of one derivation.
      # Place it in an available child slot.
      # @param child_node [Dendroid::Parsing::ParseNode]
      # @param _index [Integer] Unused
      def add_child(child_node, _index)
        idx = children.find_index(&:nil?)
        raise StandardError unless idx

        # Use first found available slot...
        super(child_node, idx)
      end

      # Is the given chart entry matching this node?
      # The chart entry matches this node if:
      #   - its origin equals to the start of the range; and,
      #   - both rules are the same; and,
      #   - each child matches this chart entry
      # @return [Boolean] true if the entry corresponds to this node.
      def match(anEItem)
        return false if range.begin != anEItem.origin

        dotted = anEItem.dotted_item
        (symbol == dotted.rule.lhs) && children.any? { |ch| ch.match(anEItem) }
      end

      # @return [FalseClass]
      def partial?
        # children.any?(&:nil?)
        false
      end

      # Return a String representation of itself
      # @return [String] text representation of itself
      def to_s
        "OR: #{symbol.name} #{range_to_s}"
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        aVisitor.visit_or_node(self)
      end
    end # class
  end # module
end # module
