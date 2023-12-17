# frozen_string_literal: true

require_relative 'dotted_item'

module Dendroid
  module GrmAnalysis
    # Mix-in module for extending the Syntax::Choice class
    # with dotted items manipulation methods
    module RuleItems
      # Build the alternative items for this choice and assign them
      # to the `items` attributes
      # @return [Array<Array<GrmAnalysis::Dottedtem>>]
      def build_items
        # AlternativeItem
        @items = Array.new(alternatives.size) { |_| [] }
        alternatives.each_with_index do |alt_seq, index|
          if alt_seq.empty?
            @items[index] << DottedItem.new(self, 0, index)
          else
            (0..alt_seq.size).each do |pos|
              @items[index] << DottedItem.new(self, pos, index)
            end
          end
        end
      end

      # Read accessor for the `items` attribute.
      # Return the dotted items for this production
      # @return [Array<Array<GrmAnalysis::Dottedtem>>]
      def items
        @items
      end

      # Return the predicted items (i.e. the alternative items with the dot at start)
      # for this choice.
      # @return [Array<GrmAnalysis::Dottedtem>]
      def predicted_items
        @items.map(&:first)
      end

      # Return the reduce items (i.e. the alternative items with the dot at end)
      # for this choice.
      # @return [Array<GrmAnalysis::Dottedtem>]
      def reduce_items
        @items.map(&:last)
      end

      # Return the next item given the provided item.
      # In other words, advance the dot by one position.
      # @param anItem [GrmAnalysis::Dottedtem]
      # @return [GrmAnalysis::Dottedtem|NilClass]
      def next_item(anItem)
        items_arr = items[anItem.alt_index]
        return nil if anItem == items_arr.last

        items_arr[anItem.position + 1]
      end
    end # module
  end # module
end # module
