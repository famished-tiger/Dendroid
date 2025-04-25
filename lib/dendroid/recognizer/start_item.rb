# frozen_string_literal: true

module Dendroid
  module Recognizer
    # A chart member that represents the start state of a recognizer pass.
    class StartItem
      # The start (top-level) symbol of the grammar
      attr_reader :symbol

      alias lhs symbol

      def initialize(start_symbol)
        @symbol = start_symbol
      end

      def to_s
        ". #{symbol.name}"
      end

      def inspect
        to_s
      end

      def algo
        :predictor
      end

      def origin
        0
      end

      def predecessors
        []
      end
    end # class
  end # module
end # module

