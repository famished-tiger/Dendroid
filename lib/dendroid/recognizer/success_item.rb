# frozen_string_literal: true

module Dendroid
  module Recognizer

    # A chart member that represents the successful completion of a recognizer pass.
    class SuccessItem
      # The start (top-level) symbol of the grammar
      attr_reader :symbol
      attr_reader :predecessors

      alias lhs symbol

      def initialize(start_symbol)
        @symbol = start_symbol
        @predecessors = []
      end

      def to_s
        "#{symbol.name} ."
      end

      def inspect
        to_s
      end

      def algo
        :completer
      end

      def origin
        0
      end

      def rule
        predecessors[0].dotted_item.rule
      end
    end # class
  end # module
end # module

