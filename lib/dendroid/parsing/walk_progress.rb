# frozen_string_literal: true

require_relative 'and_node'
require_relative 'or_node'
require_relative 'terminal_node'
require_relative 'empty_rule_node'

module Dendroid
  module Parsing
    # This object holds the current state of the visit of a Chart by one
    # ChartWalker through one single visit path. A path corresponds to a
    # chain from the current item back to the initial item(s) through the predecessors links.
    # It is used to construct (part of) the parse tree beginning from the root node.
    class WalkProgress
      # @return [Symbol] One of: :New, :Running, :Waiting, :Complete, :Forking, :Delegating
      attr_accessor :state

      # @return [Integer] rank of the item set from the chart being visited
      attr_accessor :curr_rank

      # @return [Dendroid::Recognizer::EItem] the chart entry being visited
      attr_reader :curr_item

      # When not nil, override the predecessors links of the current item
      # @return [Dendroid::Recognizer::EItem|NilClass]
      attr_accessor :predecessor

      # @return [Array<Dendroid::Parsing::CompositeParseNode>] The ancestry of current parse node.
      attr_reader :parents

      # @param start_rank [Integer] Initial rank at the start of the visit
      # @param start_item [Dendroid::Recognizer::EItem] Initial chart entry to visit
      # @param parents [Array<Dendroid::Parsing::CompositeParseNode>]
      def initialize(start_rank, start_item, parents)
        @state = :New
        @curr_rank = start_rank
        @curr_item = start_item
        @predecessor = nil
        @parents = parents
      end

      # Factory method.
      def initialize_copy(orig)
        @state = orig.state
        @curr_rank = orig.curr_rank
        @curr_item = orig.curr_item
        @predecessor = nil
        @parents = orig.parents.dup
      end

      # Current item has multiple predecessors: set the state to Forking and
      # force one of the predecessor to be the next entry to visit.
      # @param thePredecessor [Dendroid::Recognizer::EItem]
      def fork(thePredecessor)
        @state = :Forking
        @predecessor = thePredecessor
      end

      # Set the current entry being visited to the given one
      # @param anEntry [Dendroid::Recognizer::EItem]
      def curr_item=(anEntry)
        raise StandardError if anEntry.nil?

        @curr_item = anEntry
      end

      # Add a child leaf node for the given chart entry that corresponds
      # to an empty rule.
      # @param anEntry [Dendroid::Recognizer::EItem]
      # @return [Dendroid::Parsing::EmptyRuleNode]
      def add_node_empty(anEntry)
        node_empty = EmptyRuleNode.new(anEntry, curr_rank)
        add_child_node(node_empty)
      end

      # Add a leaf terminal node for the token at current rank as a child of last parent.
      # @param token [Dendroid::Lexical::Token]
      # @return [Dendroid::Parsing::TerminalNode]
      def add_terminal_node(token)
        @curr_rank -= 1
        term_node = TerminalNode.new(curr_item.prev_symbol, token, curr_rank)
        add_child_node(term_node)
      end

      # Make an AND node for the given entry as a child of last parent and
      # push this node in the ancestry
      # @param anEntry [Dendroid::Recognizer::EItem]
      # @return [Dendroid::Parsing::AndNode]
      def push_and_node(anEntry)
        node = AndNode.new(anEntry, curr_rank)
        raise StandardError unless anEntry.rule == node.rule # Fails

        add_child_node(node)
        parents.push(node)

        node
      end

      # Make an OR node as a child of last parent and
      # push this node in the ancestry.
      # @param origin [Integer] Start rank
      # #param arity [Integer] The number of alternative derivations
      # @return [Dendroid::Parsing::OrNode]
      def push_or_node(origin, arity)
        node = OrNode.new(curr_item.prev_symbol, origin, curr_rank, arity)
        add_child_node(node)
        parents.push(node)

        node
      end

      # Add the given node as a child of the last parent node.
      # @param aNode [Dendroid::Parsing::ParseNode]
      # @return [Dendroid::Parsing::ParseNode]
      def add_child_node(aNode)
        parents.last.add_child(aNode, curr_item.position - 1) unless parents.empty?
        aNode
      end

      # rubocop: disable Metrics/CyclomaticComplexity
      # rubocop: disable Metrics/PerceivedComplexity

      # Do the given EItems match one of the parent?
      # Matching = corresponds to the same rule and range
      # @param entries [Dendroid::Recognizer::EItem]
      # @param stop_at_first [Boolean] Must be true
      # @return [Array<Array<EItem, Integer>>]
      def match_parent?(entries, stop_at_first)
        matching = []
        min_origin = entries[0].origin
        first_iteration = true
        offset = 0

        parents.reverse_each do |node|
          if node.is_a?(OrNode)
            offset += 1
            next
          end
          entries.each do |ent|
            min_origin = ent.origin if first_iteration && ent.origin < min_origin
            next unless node.match(ent)

            matching << [ent, offset]
            break if stop_at_first
          end
          first_iteration = false
          break if stop_at_first && !matching.empty?

          # Stop loop when parent.origin < min(entries.origin)
          break if node.range.begin < min_origin

          offset += 1
        end

        matching
      end
    end # class

    # rubocop: enable Metrics/CyclomaticComplexity
    # rubocop: enable Metrics/PerceivedComplexity
  end # module
end # module
