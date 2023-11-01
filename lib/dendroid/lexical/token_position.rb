# frozen_string_literal: true

module Dendroid
  module Lexical
    class TokenPosition
      attr_reader :lineno
      attr_reader :column

      def initialize(line, col)
        @lineno = line
        @column = col
      end

      def to_s
        "#{lineno}:#{column}"
      end
    end # class
  end # module
end # module

