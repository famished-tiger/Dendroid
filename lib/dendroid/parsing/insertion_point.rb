# frozen_string_literal: true
require 'forwardable'
require_relative 'node_types'
require_relative 'point_state'
require_relative '../recognizer/start_item'
require_relative '../recognizer/success_item'

module Dendroid
  module Parsing

    # An insertion point is a temporary object which is used solely in the construction
    # of a parse result. An insertion point keeps track of the relation of a parse node
    # with respect of parent parse nodes.
    class InsertionPoint
      extend Forwardable

      # @return [Array<InsertionPoint>] zero or more parent insertion points
      attr_reader :parents

      # @return [ParseNode] Reference to a parse node
      attr_reader :node

      # @return [Integer] tells the number of missing child nodes
      attr_reader :dot_pos

      attr_reader :state

      # @return [Integer]
      attr_accessor :thread


      attr_accessor :expected_predecessor

      # @return [Symbol] :empty, :partial, :full, :final
      attr_reader :progeny_state

      def_delegators :@node, :origin

      # @param aThread [Integer]
      # @param aParent [InsertionPoint] An insertion that refers to a parent node of ``theNode.
      # @param theNode [ParseNode] the parse node to insert to the parse result.
      # @param theState [PointState]
      def initialize(aThread, aParent, theNode, theState)
        @thread = aThread
        @parents = aParent.nil? ? [] : [aParent]
        @node = theNode

        transmogrify(theState)
        @dot_pos = theNode.size
        if node.is_a?(CompositeParseNode)
          @progeny_state =  node.children.empty? ? :final : :empty
        else
          @progeny_state = :final
        end
      end

      # @return [String] A text representation of the insertion point.
      def to_s
        case node
        when AndNode
          node_str = node.to_s
          if full?
            node_str
          else
            chunks = node_str.split(" ")
            chunks.insert(dot_pos + 2, '^')
            chunks.join(' ')
          end

        else
          node.to_s
        end
      end

      def dotted_item
        unless node.is_a?(AndNode)
          raise StandardError
        end

        return nil if dot_pos < 0

        node.rule.items[node.alt_index][dot_pos]
      end

      def prev_dotted_item
        raise StandardError unless node.is_a?(AndNode)

        return nil if dot_pos < 0

        node.rule.items[node.alt_index][dot_pos-1]
      end

      def incomplete?
        @progeny_state == :empty || @progeny_state == :partial
      end

      def full?
        dot_pos <= 0
      end

      def final?
        @progeny_state == :final
      end

      # @return [Boolean] true iff the parse node is the root node.
      def root?
        origin.zero? && parents.size.zero?
      end

      # @return [Boolean] true if the node is shared between mutiple parent nodes.
      def shared?
        parents.size > 1
      end

      def share_with(ipoint)
        parents << ipoint
        ipoint.link_child(node)
        puts "    Share #{self} as child of #{ipoint}."
      end

      def match?(anEntry)
        return false if anEntry.is_a? Dendroid::Recognizer::StartItem
        return false if origin != anEntry.origin

        dot_pos == anEntry.dotted_item.position && node.alt_index == anEntry.dotted_item.alt_index
      end

      # Is the given entry expected given the rank value?
      # @return [Boolean]
      def expect?(anEntry, rank)
        return false if dot_pos.zero? && origin != anEntry.origin
        return false if anEntry.origin < origin
        return false if anEntry.is_a?(EItemProxy) && node.ordering != anEntry.ordering
        return false if node.ordering && progeny_state == :empty && expected_predecessor != anEntry

        if anEntry.is_a?(Dendroid::Recognizer::StartItem) || anEntry.is_a?(Dendroid::Recognizer::SuccessItem)
          dot_pos == 0 && node.rule.lhs == anEntry.symbol
        elsif anEntry.dotted_item.empty?
          dotted_item.prev_symbol == anEntry.lhs && node.upper_bound == rank
        elsif anEntry.dotted_item.final_pos?
          dotted_item.prev_symbol == anEntry.lhs && node.upper_bound == rank
        elsif dotted_item.prev_symbol.terminal?
          prev_dotted_item == anEntry.dotted_item && node.upper_bound == rank + 1
        else
          prev_dotted_item == anEntry.dotted_item
        end
      end

      def same_prediction?(anEntry, rank)
        if anEntry.is_a? Dendroid::Recognizer::StartItem
          parents.empty? && node.origin.zero? && node.symbol == anEntry.symbol
        elsif node.origin == rank
          if node.is_a?(TerminalNode)
            parents.any? do |par|
              if par.dotted_item.rule.lhs == anEntry.dotted_item.next_symbol
                par.same_prediction?(anEntry, rank)
              else
                false
              end
            end
          elsif dotted_item.rule.lhs == anEntry.dotted_item.next_symbol
            if node.ordering # The parent is an OrNode
              parents[0].parents.any? { |par| par.same_prediction?(anEntry, rank) }
            else
              parents.any? do |par|
                par.origin == anEntry.origin && par.dotted_item == anEntry.dotted_item
              end
            end
          elsif match?(anEntry)
            true
          else
            false
          end
        else
          false
        end
      end

      # Precondition: node is not a TerminalNode
      # Return this ipoint or its ancestor(s) that can be predicted from the given entry.
      # predicted means: lhs of ipoint matches next symbol of given entry
      def predicted_ipoints(anEntry, rank)
        if anEntry.is_a? Dendroid::Recognizer::StartItem
          if root? && node.symbol == anEntry.symbol
            nil
          else
            raise StandardError, 'Uncovered case'
          end
        elsif node.origin == rank
          if dotted_item.rule.lhs == anEntry.dotted_item.next_symbol
            waiters = []
            if node.ordering # The parent is an OrNode
              parents[0].parents.each do |par|
                waiters.concat(par.predicted_ipoints(anEntry, rank))
              end
            else
              parents.each do |par|
                if par.origin == anEntry.origin && par.dotted_item == anEntry.dotted_item
                  waiters << par
                end
              end
            end
            waiters.uniq
          elsif match?(anEntry)
            [self]
          else
            []
          end
        else
          []
        end
      end

      # Precondition: node is terminal node
      def predicted_ancestors(anEntry, rank)
        if anEntry.is_a? Dendroid::Recognizer::StartItem
          if root? && node.symbol == anEntry.symbol
            nil
          else
            [] # TODO: case all ancestors are full? ...
          end
        elsif node.origin == rank
          waiters = []
          parents.any? do |par|
            if par.dotted_item.rule.lhs == anEntry.dotted_item.next_symbol
              waiters.concat(par.predicted_ipoints(anEntry, rank))
            end
          end
          waiters.uniq
        else
          []
        end
      end

      def tick
        @dot_pos -= 1
      end

      def transmogrify(aState)
        raise StandardError unless aState.is_a?(PointState)

        @state = aState
      end

      # @param child_node [ParseNode] Add a child to `node`.
      # @return [InsertionPoint] the insertion point referencing the child node
      def add_child_node(child_node)
        link_child(child_node)

        new_state =  child_node.is_a?(Dendroid::Parsing::OrNode) ? Conjunction.new(child_node.children.size) : PointState.new
        child_ip = self.class.new(thread, self, child_node, new_state)
        puts "    Added #{child_ip} as child of #{self}."

        child_ip
      end

      def link_child(child_node)
        raise StandardError if full?

        tick
        node.add_child(child_node, dot_pos)
        if node.is_a?(CompositeParseNode)
          if full?
            @progeny_state = child_node.leaf? ? :final : :full
          else
            @progeny_state = :partial
          end
        end
      end

      # Make n - 1 copies of itself (n: count of parents)
      # A copy per parent except for the parent with thread_id passed as argument
      def dup_except(aThread)
        copies = []
        parents.each do |par|
          next if par.thread == aThread

          copy = dup
          copy.instance_variable_set(:@parents, [par])
          copy.thread = par.thread
          copies << copy
        end

        copies
      end

      def rollup
        return [] if root?
        return [self] unless full?

        result = []
        parents.each do |par|
          if par.full?
            result.concat(par.rollup)
          else
            result << par
          end
        end

        result
      end
    end # class
  end # module
end # module
