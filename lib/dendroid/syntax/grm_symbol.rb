# frozen_string_literal: true

module Dendroid
  # The namespace for all classes used to build a grammar.
  module Syntax
    # Abstract class for grammar symbols.
    # A grammar symbol is an element that appears in grammar rules.
    class GrmSymbol
      # @return [String] The name of the grammar symbol
      attr_reader :name

      # Constructor.
      # aSymbolName [String] The name of the grammar symbol.
      def initialize(symbolName)
        @name = valid_name(symbolName)
      end

      # The String representation of the grammar symbol
      # @return [String]
      def to_s
        name.to_s
      end

      # Equality testing (based on symbol name)
      # @return [Boolean]
      def ==(other)
        name == other.name
      end

      private

      def valid_name(symbolName)
        if symbolName.is_a?(String)
          stripped = symbolName.strip
          if stripped.empty?
            err_msg = 'A symbol name cannot be empty.'
            raise StandardError, err_msg
          end
          stripped.to_sym
        else
          symbolName
        end
      end
    end # class
  end # module
end # module
