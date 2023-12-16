# frozen_string_literal: true

require_relative 'parse_node'

module Dendroid
  module Parsing
    class CompositeParseNode < ParseNode
      attr_reader :range
      attr_reader :children

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
