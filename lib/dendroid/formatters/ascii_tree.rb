# frozen_string_literal: true

require_relative 'base_formatter'

# A formatter class that draws parse trees by using characters
class Asciitree < BaseFormatter
  # TODO
  attr_reader(:curr_path)

  # For each node in curr_path, there is a corresponding string value.
  # Allowed string values are: 'first', 'last', 'first_and_last', 'other'
  attr_reader(:ranks)

  # @return [String] The character pattern used for rendering
  # a parent - child nesting
  attr_reader(:and_nesting_prefix)

  # TODO: comment
  attr_reader(:or_nesting_prefix)

  # @return [String] The character pattern used for a blank indentation
  attr_reader(:blank_indent)

  # @return [String] The character pattern for indentation and nesting
  # continuation.
  attr_reader(:continuation_indent)

  # Constructor.
  # @param anIO [IO] The output stream to which the parse tree
  # is written.
  def initialize(anIO)
    super(anIO)
    @curr_path = []
    @ranks = []

    @and_nesting_prefix = '+-- '
    @or_nesting_prefix = '/-- '
    @blank_indent = '    '
    @continuation_indent = '|   '
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor is about to visit
  # the children of a non-terminal node
  # @param parent [NonTerminalNode]
  # @param _children [Array<ParseTreeNode>] array of children nodes
  def before_subnodes(parent, _children)
    rank_of(parent)
    curr_path << parent
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor is about to visit
  # a non-terminal node
  # @param aNonTerm [NonTerminalNode]
  def before_and_node(aNonTerm)
    emit_and(aNonTerm)
  end

  def before_or_node(aNonTerm)
    emit_or(aNonTerm)
  end

  def before_empty_rule_node(anEmptyRuleNode)
    emit_and(anEmptyRuleNode, ': .')
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor is about to visit
  # a terminal node
  # @param aTerm [TerminalNode]
  def before_terminal(aTerm)
    emit_terminal(aTerm, ": '#{aTerm.token.source}'")
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor completed the visit of
  # the children of a non-terminal node.
  # @param _parent [NonTerminalNode]
  # @param _children [Array] array of children nodes
  def after_subnodes(_parent, _children)
    curr_path.pop
    ranks.pop
  end

  private

  # Parent node is last node in current path
  # or current path is empty (then aChild is root node)
  def rank_of(aChild)
    if curr_path.empty?
      rank = 'root'
    elsif curr_path[-1].children.size == 1
      rank = 'first_and_last'
    else
      parent = curr_path[-1]
      siblings = parent.children
      siblings_last_index = siblings.size - 1
      rank = case siblings.find_index(aChild)
             when 0 then 'first'
             when siblings_last_index then 'last'
             else
               'other'
             end
    end
    ranks << rank
  end

  # 'root', 'first', 'first_and_last', 'last', 'other'
  def path_prefix(connector)
    return '' if ranks.empty?

    prefix = +''
    @ranks.each_with_index do |rank, i|
      next if i.zero?

      case rank
      when 'first', 'other'
        prefix << continuation_indent

      when 'last', 'first_and_last', 'root'
        prefix << blank_indent
      end
    end

    nesting = (connector == :and) ? and_nesting_prefix : or_nesting_prefix
    prefix << nesting
    prefix
  end

  def emit_and(aNode, aSuffix = '')
    output.puts("#{path_prefix(:and)}#{aNode.rule.lhs.name}#{aSuffix}")
  end

  def emit_or(aNode, aSuffix = '')
    output.puts("#{path_prefix(:or)}OR #{aNode.symbol.name}#{aSuffix}")
  end

  def emit_terminal(aNode, aSuffix = '')
    output.puts("#{path_prefix(:and)}#{aNode.symbol.name}#{aSuffix}")
  end
end # class