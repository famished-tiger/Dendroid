# frozen_string_literal: true

module Dendroid
  module Lexical
    # Keeps track of the position of a token in the input stream.
    class TokenPosition
      # @return [Integer] The line number where the token begins
      attr_reader :lineno

      # @return [Integer] The column number where the token begins
      attr_reader :column

      # Constructor
      # @param line [Integer] The line number where the token begins
      # @param col [Integer] The column number where the token begins
      def initialize(line, col)
        @lineno = line
        @column = col
      end

      # Return the position of the start of the token in line:col format
      # @return [String]
      def to_s
        "#{lineno}:#{column}"
      end
    end # class
  end # module
end # module
