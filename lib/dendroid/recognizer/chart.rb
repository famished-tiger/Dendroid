# frozen_string_literal: true

require_relative 'item_set'

module Dendroid
  module Recognizer
    # Also called a parse table. It records the progress of the
    # Earley recognizer whens its verifies the compliance of the input text
    # to the language grammar rules.
    # It essentially consists in an array of item sets.
    # If n is the number of input tokens then the chart has n + 1 entry sets.
    class Chart
      extend Forwardable

      # @return [Array<Recognizer::ItemSet>] The array of item sets
      attr_reader :item_sets

      # @return [Array<Dendroid::Lexical::Token>] The input tokens
      attr_reader :tokens

      # @return [Boolean] Indicates whether the recognizer successfully processed the whole input
      attr_writer :success

      # @return [StandardError] The exception class in case of an error found by the recognizer
      attr_reader :failure_class

      # @return [String] The error message
      attr_reader :failure_reason

      def_delegators :@item_sets, :[], :last, :size

      # Constructor
      # Initialize the chart with one empty item set.
      def initialize
        @item_sets = []
        @success = false
        append_new_set
      end

      # Add a new empty item set at the end of the array of item sets
      def append_new_set
        item_sets << ItemSet.new
      end

      # Add an EItem to the last item set
      # @param e_item [EItem]
      def seed_last_set(e_item)
        item_sets.last.add_item(e_item)
      end

      # @param input_tokens [Array<Dendroid::Lexical::Token>] The input tokens
      def tokens=(input_tokens)
        @tokens = input_tokens
      end

      # Return true if the input text is valid according to the grammar.
      # @return [Boolean]
      def successful?
        @success
      end

      # Set the error cause.
      # @param exception_class [StandardError] Exception class
      # @param message [String] Error message
      def failure(exception_class, message)
        @failure_class = exception_class
        @failure_reason = message
      end
    end # class
  end # module
end # module
