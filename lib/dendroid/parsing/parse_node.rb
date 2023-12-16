# frozen_string_literal: true

module Dendroid
  module Parsing
    class ParseNode
      # @return [Array<Integer>] The range of input tokens that match this node.
      attr_reader :range

      def initialize(lowerBound, upperBound)
        @range = valid_range(lowerBound, upperBound)
      end

      def to_s
        "[#{range[0]}, #{range[1]}]"
      end

      private

      def valid_range(lowerBound, upperBound)
        raise StandardError unless lowerBound.is_a?(Integer) && upperBound.is_a?(Integer)

        [lowerBound, upperBound]
      end
    end # class
  end # module
end # module
