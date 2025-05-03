# frozen_string_literal: true

require 'set'
require_relative 'base_formatter'

class Mermaid < BaseFormatter
  attr_reader :visitees

  attr_reader :children_visited

  def before_visit(rootNode)
    @visitees = Set.new([])
    @children_visited = Set.new([])
    write("graph TD\n")
  end

  def after_visit(rootNode)
    write("classDef Or_node fill:#f96,stroke:#333,stroke-width:2px;\n")
    write("classDef And_node fill:#f9f,stroke:#333,stroke-width:4px;\n")
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor is about to visit
  # a non-terminal node
  # @param and_node [AndNode]
  def before_and_node(and_node)
    return if visitees.include? and_node

    visitees.add(and_node)
    write("n_#{and_node.object_id}[\"#{and_node}\"]:::And_node\n")
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor is about to visit
  # a non-terminal node
  # @param or_node [OrNode]
  def before_or_node(or_node)
    return if visitees.include? or_node

    visitees.add(or_node)
    write("n_#{or_node.object_id}(((\"#{or_node}\"))):::Or_node\n")
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor is about to visit
  # the children of a non-terminal node
  # @param parent [NonTerminalNode]
  # @param children [Array<ParseTreeNode>] array of children nodes
  def after_subnodes(parent, children)
    return if children_visited.include? parent

    children.each do |ch|
      write("n_#{parent.object_id} --> n_#{ch.object_id}\n" )
    end
    children_visited.add(parent)
  end

  def before_empty_rule_node(anEmptyRuleNode)
    return if visitees.include? anEmptyRuleNode

    visitees.add(anEmptyRuleNode)
    write("n_#{anEmptyRuleNode.object_id}((\"#{anEmptyRuleNode}\"))\n")
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor is about to visit
  # a terminal node
  # @param aTerm [TerminalNode]
  def before_terminal(aTerm)
    return if visitees.include? aTerm

    visitees.add(aTerm)
    write("n_#{aTerm.object_id}([\"#{aTerm}\"])\n")
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor completed the visit of
  # a terminal node.
  # @param aTerm [TerminalNode]
  def after_terminal(aTerm)
    # # Escape all opening and closing square brackets
    # escape_lbrackets = aTerm.token.source.gsub(/\[/, '\[')
    # escaped = escape_lbrackets.gsub(/\]/, '\]')
    # write("#{escaped}]")
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor completed the visit of
  # a non-terminal node
  # @param _nonterm [NonTerminalNode]
  def after_and_node(_nonterm)
    # write(']')
  end

  private

  def declare_node(aNode)
    unless visitees.include? aNode
      visitees.add(aNode)
      write("n_#{aNode.object_id}[\"#{aNode}\"]\n")
    end
  end

  def write(aText)
    output.write(aText)
  end
end # class