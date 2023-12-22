# frozen_string_literal: true

module Dendroid
  # Namespace for all classes needed for implementing a generic parser.
  # The goal is to take the output from the Earley recognizer (i.e. a chart object),
  # visit it and build a data structure (a parse tree or a shared parse forest) that is much
  # more convenient for subsequent processing (e.g. semantic analysis of a compiler/interpreter).
  module Parsing
    # An abstract class (i.e. a generalization) for elements forming a parse tree (forest).
    # A parse tree is a graph data structure that represents the parsed input text into a tree-like hierarchy
    # of elements constructed by applying syntax rules of the language at hand.
    # A parse forest is a data structure that merges a number parse trees into one graph.
    # Contrary to parse trees, a parse forests can represent the results of an ambiguous parsing.
    class ParseNode
      # @return [Range] The range of indexes of the input tokens that match this node.
      attr_reader :range

      # @param lowerBound [Integer] Rank of first input token that is matched by this node
      # @param upperBound [Integer] Rank of last input token that is matched by this node
      def initialize(lowerBound, upperBound)
        @range = valid_range(lowerBound, upperBound)
      end

      protected

      def range_to_s
        "[#{range}]"
      end

      private

      def valid_range(lowerBound, upperBound)
        raise StandardError unless lowerBound.is_a?(Integer) && upperBound.is_a?(Integer)

        lowerBound..upperBound
      end
    end # class
  end # module
end # module
