# frozen_string_literal: true
require 'forwardable'

module Dendroid
  module Parsing
    # A hybrid queue that combines the behaviour of a FIFO queue with a priority queue.
    # Queued elements are put in one of two bins.
    # To each bin is associated a priority (which is an integer value).
    # - At any moment, there exists at most two priority values, which are consecutive values.
    class SwappingQueue
      # @return [Integer] Priority value of elements in FIFO 'queue'.
      attr_reader :priority

      # @return [Array] FIFO of elements.
      attr_reader :queue

      # @return [Array] FIFO of elements with lower priority.
      attr_reader :lobby

      # A lambda that takes an element and returns true if that element must be assigned
      # a lower priority.
      # @return [Lambda]
      attr_reader :element_tester

      # A lambda that takes an array of element and returns true if that element is already
      # present.
      # @return [Lambda]
      attr_reader :element_comparator

      def initialize(max_priority, tester, comparator)
        @priority = max_priority
        @queue = []
        @lobby = []
        @element_tester = tester
        @element_comparator = comparator
      end

      # @return [Boolean] true iff the queue has no element.
      def empty?
        queue.empty? && lobby.empty?
      end

      # @return [Integer] the number of elements in the queue.
      def size
        queue.size + lobby.size
      end

      # @return [String] A text representation of the queue contents.
      def to_s
        "queue: #{queue}, lobby: #{lobby}"
      end

      # Remove all elements from the queue.
      def clear
        queue.clear
        lobby.clear
      end

      def enqueue(element)
      # def enqueue(thread_id, element, prev_element, algo)
      #   quadruplet = [thread_id, algo, prev_element, element]
      #
      #   if algo == :scanner
      #     already_present = lobby.any? { |(_, _, el)| el == element }
      #     lobby << quadruplet unless already_present
      #   else
      #     queue << quadruplet
      #   end

        if element_tester.call(element)
          already_present = lobby.any? { |el | element_comparator.call(element, el) }
          lobby << element unless already_present
        else
          queue << element
        end
      end

      # Remove an element from the queue. If queue is empty, then return nil.
      # @return [Object | NilClass] removed element or nil if queue is empty.
      def dequeue
        return nil if empty?

        swap_queues if queue.empty?
        @queue.shift
      end

      # Return the element ready to be dequeued. Otherwise queue is empty, then return nil.
      # @return [Object | NilClass] element or nil if queue is empty.
      def peek
        return nil if empty?

        swap_queues if queue.empty?
        queue[0]
      end

      private

      # Swapping 'main' queue and lobby
      def swap_queues
        temp = @queue
        @queue = @lobby
        @lobby = temp
        @priority -= 1
      end
    end # class
  end # module
end # module
