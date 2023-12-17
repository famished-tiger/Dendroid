# frozen_string_literal: true

require_relative 'and_node'
require_relative 'or_node'
require_relative 'terminal_node'
require_relative 'empty_rule_node'

module Dendroid
  module Parsing
    class WalkProgress
      attr_accessor :state
      attr_accessor :curr_rank
      attr_reader :curr_item
      attr_accessor :predecessor
      attr_reader :parents

      # rubocop: disable Metrics/CyclomaticComplexity
      # rubocop: disable Metrics/PerceivedComplexity

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

      def fork(thePredecessor)
        @state = :Forking
        @predecessor = thePredecessor
      end

      def curr_item=(anEntry)
        raise StandardError if anEntry.nil?

        @curr_item = anEntry
      end

      def add_node_empty(anEntry)
        node_empty = EmptyRuleNode.new(anEntry, curr_rank)
        add_child_node(node_empty)
      end

      # Add a terminal node for terminal at current rank as a child of last parent
      def add_terminal_node(token)
        @curr_rank -= 1
        term_node = TerminalNode.new(curr_item.prev_symbol, token, curr_rank)
        add_child_node(term_node)
      end

      # Add an AND node for given entry as a child of last parent
      def push_and_node(anEntry)
        node = ANDNode.new(anEntry, curr_rank)
        raise StandardError unless anEntry.rule == node.rule # Fails

        add_child_node(node)
        parents.push(node)

        node
      end

      def push_or_node(origin, arity)
        node = OrNode.new(curr_item.prev_symbol, origin, curr_rank, arity)
        add_child_node(node)
        parents.push(node)

        node
      end

      def add_child_node(aNode)
        parents.last.add_child(aNode, curr_item.position - 1)
        aNode
      end

      # Do the given EItems match one of the parent?
      # Matching = corresponds to the same rule and range
      # @return [Array<EItem>]
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
          break if node.range[0] < min_origin

          offset += 1
        end

        matching
      end
    end # class

    # rubocop: enable Metrics/CyclomaticComplexity
    # rubocop: enable Metrics/PerceivedComplexity
  end # module
end # module
