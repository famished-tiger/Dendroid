# frozen_string_literal: true

require_relative 'base_formatter'

class BracketNotation < BaseFormatter
  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor is about to visit
  # a non-terminal node
  # @param and_node [AndNode]
  def before_and_node(and_node)
    write("[#{and_node.rule.lhs.name} ")
  end

  def before_empty_rule_node(anEmptyRuleNode)
    write("[#{anEmptyRuleNode.rule.lhs.name}]")
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor is about to visit
  # a terminal node
  # @param aTerm [TerminalNode]
  def before_terminal(aTerm)
    write("[#{aTerm.symbol.name} ")
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor completed the visit of
  # a terminal node.
  # @param aTerm [TerminalNode]
  def after_terminal(aTerm)
    # Escape all opening and closing square brackets
    escape_lbrackets = aTerm.token.source.gsub(/\[/, '\[')
    escaped = escape_lbrackets.gsub(/\]/, '\]')
    write("#{escaped}]")
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor completed the visit of
  # a non-terminal node
  # @param _nonterm [NonTerminalNode]
  def after_and_node(_nonterm)
    write(']')
  end

  private

  def write(aText)
    output.write(aText)
  end
end # class
