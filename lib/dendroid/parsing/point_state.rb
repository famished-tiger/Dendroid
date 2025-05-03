# frozen_string_literal: true

require_relative 'e_item_proxy'

module Dendroid
  module Parsing
    class PointState
      def init_pos(ipoint)
        ipoint.node.size
      end

      def descendents
        []
      end

      def child_state(_pred)
        PointState.new
      end

      def match?(ipoint, anEntry, _pred)
        return false if ipoint.origin != anEntry.origin

        if anEntry.is_a?(Dendroid::Recognizer::StartItem)
          ipoint.dot_pos == 0 && ipoint.node.rule.lhs == anEntry.symbol
        else
          ipoint.dotted_item == anEntry.dotted_item
        end
      end

      def make_descendent(ipoint, child_node, pred)

        InsertionPoint.new(ipoint, child_node, child_state(pred))
      end

      def to_finalize(ipoint)
        return :final unless ipoint.is_a?(AndNode)

        ipoint.full? ? :final : ipoint.progeny_state
      end

      def update
        ; # Do nothing
      end
    end # class


    class Replicated < PointState
      attr_reader :predecessor
      attr_reader :updated

      def initialize(pred)
        @predecessor = pred.is_a?(EItemProxy) ? pred.predecessors[0] : pred
        @updated = nil
      end

      def match?(ipoint, anEntry, pred)
        return false unless super(ipoint, anEntry, pred)

        return true if pred.nil?

        # if deferred
        # @deferred = false # One-shot state
        # predecessor == pred.predecessors[0]
        if ipoint.dotted_item.final_pos? || updated == :waiting # Comparison with predecessor occurs once
          predecessor == pred
        else
          true
        end
      end

      def update
        @updated = :done
      end
    end # class

    class Conjunction < PointState
      attr_reader :arity
      attr_reader :completed_threads

      def initialize(child_count)
        super()

        @arity = child_count
        @completed_threads = {}
      end

      def done?
        completed_threads.size == arity
      end

      def thread_completed(thread_id)
        @completed_threads[thread_id] = true
      end
    end

    class ORed < PointState
      attr_reader :descendents
      attr_writer :pred_matching

      def initialize
        @descendents = []
        @count_final = 0
        @final = nil
        @pred_matching = false
      end

      def init_pos(ipoint)
        ipoint.node.children.size
      end

      def child_state(pred)
        @pred_matching ? Replicated.new(pred) : super(pred)
      end


      def to_finalize(ipoint)
        return :final if @final

        return ipoint.progeny_state unless ipoint.full?

        @count_final += 1
        # all_final = descendents.all? { descendents.progeny_state == :final }
        @final = true if @count_final == ipoint.node.children.size
        @final ? :final : :full
      end

      def match?(ipoint, anEntry, _pred)
        return false if ipoint.origin != anEntry.origin
        ipoint_symb = ipoint.node.symbol

        begin
          entry_symb = nil
          if anEntry.is_a?(Dendroid::Recognizer::EItem) || anEntry.is_a?(EItemProxy)
            if anEntry.dotted_item.initial_pos?
              entry_symb = anEntry.dotted_item.rule.lhs
            else
              position = anEntry.dotted_item.position
              rhs = anEntry.dotted_item.rule.alternatives[anEntry.dotted_item.alt_index]
              (position - 1).downto(0) do |index|
                entry_symb = rhs.members[index]
                break unless entry_symb.void?

                break if entry_symb == ipoint_symb

                entry_symb = anEntry.dotted_item.rule.lhs if index.zero?
              end
              # entry_symb = anEntry.dotted_item.prev_symbol
            end
          elsif anEntry.is_a?(Dendroid::Recognizer::SuccessItem)
            entry_symb = anEntry.symbol
          else
            entry_symb = anEntry.dotted_item.rule.lhs
          end
          ipoint_symb == entry_symb
        rescue NoMethodError
          raise StandardError, 'Boom'
        end
      end

      def make_descendent(ipoint, child_node, pred)
        desc = super(ipoint, child_node, pred)
        descendents << desc
        desc
      end
    end # class
  end # module
end # module

