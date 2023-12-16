# frozen_string_literal: true

require_relative 'composite_parse_node'

module Dendroid
  module Parsing
    class OrNode  < CompositeParseNode
      attr_reader :symbol

      def initialize(sym, lower, upper, arity)
        @symbol = sym
        super(lower, upper, arity)
      end

      def add_child(child_node, _index)
        idx = children.find_index(&:nil?)
        if idx
          # Use first found available slot...
          super(child_node, idx)
          if children.size > 3
            raise StandardError
          end
        else
          raise StandardError
        end
      end

      def match(anEItem)
        return false if range[0] != anEItem.origin

        dotted = anEItem.dotted_item
        (symbol == dotted.rule.lhs) && children.any? { |ch| ch.match(anEItem) }
      end

      def partial?
        # children.any?(&:nil?)
        false
      end

      def to_s
        "OR: #{symbol.name} #{range}"
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        aVisitor.visit_or_node(self)
      end
    end # class
  end # module
end # module
