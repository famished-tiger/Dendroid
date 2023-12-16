# frozen_string_literal: true

class ParseTreeVisitor
  # Link to the result root node of the tree (forest)
  attr_reader(:root)

  # List of objects that subscribed to the visit event notification.
  attr_reader(:subscribers)

  # Indicates the kind of tree traversal to perform: :post_order, :pre-order
  attr_reader(:traversal)

  # Build a visitor for the given root.
  # @param aParseTree [ParseTree] the parse tree to visit.
  def initialize(aParseTree, aTraversalStrategy = :post_order)
    raise StandardError if aParseTree.nil?

    @root = aParseTree
    @subscribers = []
    @traversal = aTraversalStrategy
  end

  # Add a subscriber for the visit event notifications.
  # @param aSubscriber [Object]
  def subscribe(aSubscriber)
    subscribers << aSubscriber
  end

  # Remove the given object from the subscription list.
  # The object won't be notified of visit events.
  # @param aSubscriber [Object]
  def unsubscribe(aSubscriber)
    subscribers.delete_if { |entry| entry == aSubscriber }
  end

  # The signal to begin the visit of the parse tree.
  def start
    root.accept(self)
  end

  # Visit event. The visitor is about to visit the root.
  # @param aParseTree [ParseTree] the root to visit.
  def start_visit_root(aParseTree)
    broadcast(:before_root, aParseTree)
  end

  # Visit event. The visitor is about to visit the given non terminal node.
  # @param aNonTerminalNode [ANDNode] the node to visit.
  def visit_and_node(aNonTerminalNode)
    if @traversal == :post_order
      broadcast(:before_and_node, aNonTerminalNode)
      traverse_subnodes(aNonTerminalNode)
    else
      traverse_subnodes(aNonTerminalNode)
      broadcast(:before_and_node, aNonTerminalNode)
    end
    broadcast(:after_and_node, aNonTerminalNode)
  end

  # Visit event. The visitor is about to visit the given non terminal node.
  # @param aNonTerminalNode [OrNode] the node to visit.
  def visit_or_node(aNonTerminalNode)
    if @traversal == :post_order
      broadcast(:before_or_node, aNonTerminalNode)
      traverse_subnodes(aNonTerminalNode)
    else
      traverse_subnodes(aNonTerminalNode)
      broadcast(:before_or_node, aNonTerminalNode)
    end
    broadcast(:after_or_node, aNonTerminalNode)
  end

  # Visit event. The visitor is visiting the
  # given terminal node.
  # @param anEmptyRuleNode [EmptyRuleNode] the node to visit.
  def visit_empty_rule_node(anEmptyRuleNode)
    broadcast(:before_empty_rule_node, anEmptyRuleNode)
    broadcast(:after_empty_rule_node, anEmptyRuleNode)
  end

  # Visit event. The visitor is visiting the
  # given terminal node.
  # @param aTerminalNode [TerminalNode] the terminal to visit.
  def visit_terminal(aTerminalNode)
    broadcast(:before_terminal, aTerminalNode)
    broadcast(:after_terminal, aTerminalNode)
  end

  # Visit event. The visitor has completed its visit of the given
  # non-terminal node.
  # @param aNonTerminalNode [NonTerminalNode] the node to visit.
  def end_visit_nonterminal(aNonTerminalNode)
    broadcast(:after_and_node, aNonTerminalNode)
  end

  # Visit event. The visitor has completed the visit of the root.
  # @param aParseTree [ParseTree] the root to visit.
  def end_visit_root(aParseTree)
    broadcast(:after_root, aParseTree)
  end

  private

  # Visit event. The visitor is about to visit the subnodes of a non
  # terminal node.
  # @param aParentNode [NonTeminalNode] the (non-terminal) parent node.
  def traverse_subnodes(aParentNode)
    subnodes = aParentNode.children
    broadcast(:before_subnodes, aParentNode, subnodes)

    # Let's proceed with the visit of subnodes
    subnodes.each { |a_node| a_node.accept(self) }

    broadcast(:after_subnodes, aParentNode, subnodes)
  end

  # Send a notification to all subscribers.
  # @param msg [Symbol] event to notify
  # @param args [Array] arguments of the notification.
  def broadcast(msg, *args)
    subscribers.each do |subscr|
      next unless subscr.respond_to?(msg) || subscr.respond_to?(:accept_all)

      subscr.send(msg, *args)
    end
  end
end # class
