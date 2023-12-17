# frozen_string_literal: true

require_relative 'parse_node'

module Dendroid
  module Parsing
    class TerminalNode < ParseNode
      # @return [Dendroid::Syntax::Terminal] Terminal symbol of matching token.
      attr_reader :symbol

      # @return [Dendroid::Lexical::Token] Matching input token object.
      attr_reader :token

      def initialize(sym, tok, rank)
        super(rank, rank + 1)
        @symbol = sym
        @token = tok
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        aVisitor.visit_terminal(self)
      end

      def to_s
        display_val = token.is_a?(Dendroid::Lexical::Literal) ? ": #{token.value}" : ''
        "#{symbol.name}#{display_val} #{super}"
      end
    end # class
  end # module
end # module
