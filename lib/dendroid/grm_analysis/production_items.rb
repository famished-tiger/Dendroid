# frozen_string_literal: true

require_relative 'dotted_item'

module Dendroid
  module GrmAnalysis
    # Mix-in module for extending the Dendroid::Syntax::Production class
    # with dotted items manipulation methods and an attribute named `items`.
    module ProductionItems
      # Build the dotted items for this production and assign them
      # to the `items` attributes
      # @return [Array<GrmAnalysis::DottedItem>]
      def build_items
        @items = if empty?
                   [DottedItem.new(self, 0)]
                 else
                   (0..body.size).reduce([]) do |result, pos|
                     result << GrmAnalysis::DottedItem.new(self, pos)
                   end
                 end
      end

      # Read accessor for the `items` attribute.
      # Return the dotted items for this production
      # @return [Array<GrmAnalysis::DottedItem>]
      def items
        @items
      end

      # Return the predicted item (i.e. the dotted item with the dot at start)
      # for this production.
      # @return [Array<GrmAnalysis::DottedItem>]
      def predicted_items
        [@items.first]
      end

      # Return the reduce item (i.e. the dotted item with the dot at end)
      # for this production.
      # @return [Array<GrmAnalysis::DottedItem>]
      def reduce_items
        [@items.last]
      end

      # Return the next item given the provided item.
      # In other words, advance the dot by one position.
      # @param anItem [GrmAnalysis::DottedItem]
      # @return [GrmAnalysis::DottedItem|NilClass]
      def next_item(anItem)
        return nil if anItem == @items.last

        @items[anItem.position + 1]
      end
    end # module
  end # module
end # module
