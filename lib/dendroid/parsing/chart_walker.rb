# frozen_string_literal: true

require_relative 'node_types'
require_relative 'swapping_queue'

module Dendroid
  module Parsing
    # A chart walker visits Earley entries in a chart. It starts backwards from the success item
    # until it reaches the start item.
    # It uses the `predecessors` link to jump from one entry to other ones.
    # Entries with higher rank are visited first before visiting entries with a lower rank.
    class ChartWalker
      # @return [Dendroid::Recognizer::Chart]
      attr_reader :chart

      # @return [SwappingQueue] The queue of entries still to visit.
      attr_reader :visit_queue

      # @param aChart [Dendroid::Recognizer::Chart]
      def initialize(aChart)
        @last_thread_id = -1
        @chart = aChart

        # queue will contain quadruplets: [thread_id, algo, prev_element, element]
        algo_tester = ->(quad) { quad[1] == :scanner }
        comparator = ->(previous, quad) { previous == quad[2] }
        @visit_queue = SwappingQueue.new(chart.item_sets.size - 1, algo_tester, comparator)
      end

      # @return [Boolean] true if there is no entry to visit
      def done?
        visit_queue.empty?
      end

      # Start the visit of the chart. Success entry is identified.
      # Its predecessor is put in the queue
      def start
        success = chart.success_entry
        rank = curr_rank
        if success.predecessors.size == 1
          visitee = success.predecessors[0]
          enqueue_entry(new_thread_id, visitee, success, success.algo)
        else
          raise StandardError, 'Internal error. Success entry has multiple predecessors.'
        end
      end

      # Shorter argument list
      def enqueue(thread_id, prev_visitee, visitee)
        # quadruplet: [thread_id, algo, prev_element, element]
        visit_queue.enqueue([thread_id, prev_visitee.algo, prev_visitee, visitee])
      end

      def dequeue
        visit_queue.dequeue
      end

      def curr_rank
        visit_queue.priority
      end

      # Factory method. Creates a terminal node for given terminal symbol
      # occurring at current rank.
      # @return [TerminalNode]
      def new_terminal_node(symbol)
        rank = curr_rank
        TerminalNode.new(symbol, chart.tokens[rank], rank)
      end

      # Factory method. Creates an AND node for given entry
      # occurring at current rank.
      # @return [AndNode]
      def new_and_node(entry, rank)
        AndNode.new(entry, rank)
      end

      def enqueue_predecessors_of(thread_id, entry)
        algorithm = entry.algo
        entry.predecessors.each do |pred|
          # quadruplet: [thread_id, algo, prev_element, element]
          visit_queue.enqueue([thread_id, algorithm, entry, pred])
        end
      end

      def enqueue_entry(thread_id, visitee, prev_visitee, algorithm)
        # quadruplet: [thread_id, algo, prev_element, element]
        visit_queue.enqueue([thread_id, algorithm, prev_visitee, visitee])
      end

      def new_thread_id
        @last_thread_id += 1
      end
    end # class
  end # module
end # module


