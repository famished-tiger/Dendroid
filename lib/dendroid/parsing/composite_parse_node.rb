# frozen_string_literal: true

require_relative 'parse_node'

module Dendroid
  module Parsing
    # Composite Pattern. A specialization of parse nodes that have themselves children nodes.
    class CompositeParseNode < ParseNode
      # @return [Array<Dendroid::Parsing::ParseNode|NilClass>] Sub-nodes. Nil values represent available slots
      attr_reader :children

      # @param lowerBound [Integer] Rank of first input token that is matched by this node
      # @param upperBound [Integer] Rank of last input token that is matched by this node
      # @param child_count [Integer] The expected number of child nodes
      def initialize(lowerBound, upperBound, child_count)
        super(lowerBound, upperBound)
        @children = Array.new(child_count, nil)
      end

      def add_child(child_node, index)
        children[index] = child_node
      end
    end # class
  end # module
end # module
