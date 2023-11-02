# frozen_string_literal: true

require_relative 'item_set'

module Dendroid
  module Recognizer
    # Also called a parse table.
    # Assuming that n == number of input tokens,
    # then the chart is an array with n + 1 entry sets.
    class Chart
      extend Forwardable

      # @return [Array<Recognizer::ItemSet>] The array of item sets
      attr_reader :item_sets

      # @return [Boolean] Indicates whether the recognizer successfully processed the whole input
      attr_writer :success

      # @return [StandardError] The exception class in case of an error found by the recognizer
      attr_accessor :failure_class

      # @return [String] The error message
      attr_accessor :failure_reason

      def_delegators :@item_sets, :[], :last, :size

      # Constructor
      # Initialize the chart with one empty item set.
      def initialize
        @item_sets = []
        @success = false
        append_new_set
      end

      # Add a new empty item set at the end of the array of item sets
      def append_new_set()
        item_sets << ItemSet.new
      end

      # Add an EItem to the last item set
      # @param e_item [EItem]
      def seed_last_set(e_item)
        item_sets.last.add_item(e_item)
      end

      # Return true if the input text is valid according to the grammar.
      # @return [Boolean]
      def successful?
        @success
      end
    end # class
  end # module
end # module
