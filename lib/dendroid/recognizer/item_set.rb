# frozen_string_literal: true

module Dendroid
  module Recognizer
    # Holds the EItem identified by the recognizer when processing at token at given rank.
    class ItemSet
      extend Forwardable

      # @return [Recognizer::EItem]
      attr_reader :items

      def_delegators :@items, :clear, :each, :empty?, :select, :size

      def initialize
        @items = []
      end

      # Add an Earley item to the set if not yet present.
      # @param anItem [Recognizer::EItem]
      # @return [Recognizer::EItem] the item in the set
      def add_item(anItem)
        idx = items.find_index anItem
        return items[idx] if idx

        @items << anItem
        anItem
      end

      # Find the items that expect a given grammar symbol
      # @param aSymbol [Denroid::Syntax::GrmSymbol]
      # @return [void]
      def items_expecting(aSymbol)
        items.select { |itm| itm.expecting?(aSymbol) }
      end

      # Return a text representation of the item set
      # @return [String]
      def to_s
        items.join("\n")
      end
    end # class
  end # module
end # module
