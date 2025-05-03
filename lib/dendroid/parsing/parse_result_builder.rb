# frozen_string_literal: true
require 'forwardable'

require_relative 'insertion_point'
require_relative 'chart_walker'
require_relative 'scaffold'

module Dendroid
  module Parsing
    class ParseResultBuilder
      attr_reader :chart_walker
      attr_reader :scaffold

      def initialize
      end

      def run(aChart)
        reset(aChart)
        curr_t_id = chart_walker.start

        i = 0
        until chart_walker.done? do
          puts "i = #{i}, #{chart_walker.visit_queue}"
          (curr_t_id, algo, prev_visitee, visitee) = dequeue
          puts "  Visitee: #{visitee}, prev_visitee: #{prev_visitee}"
          puts "  catwalk: {#{scaffold.catwalk_to_text}}"
          if visitee.is_a?(Dendroid::Recognizer::StartItem) && chart_walker.done?
            break
          end
          rank = chart_walker.curr_rank

          case algo
          when :predictor
            step_predictor(curr_t_id, visitee, rank)

          when :scanner
            step_scanner(curr_t_id, visitee, rank)

          when :completer
            if visitee.dotted_item.empty?
              step_empty_rule(curr_t_id, visitee, rank)
            else
              step_completer(curr_t_id, visitee, rank, prev_visitee)
           end
          else
            raise StandardError, "Not implemented #{algo}"
          end
          if i == 4
            puts 'Woof!'
            # break
          end
          i += 1

        end

        scaffold.root.node
      end

      private

      def reset(aChart)
        @chart_walker = ChartWalker.new(aChart)
        @scaffold = Scaffold.new(aChart.tokens.size)
      end

      # anEntry has a dot at start position.
      # We look for the ip on catwalk for given thread
      # Test: curr_ip and entry should have:
      # - same origin, same rhs, same dot position => same dotted item
      # catwalk: remove curr_ip from catwalk, replace by parent(s) in their respective threads
      # enqueue: entries matching the parents
      # anEntry							 | nil curr_ip | no parent | one parent not OrNode | one parent OrNode | multiple parents|
      # ---------------------|-------------|-----------|-----------------------|-------------------|-----------------|
      # no_predecessor       | final 1     |  final 2  | ERROR                 | ERROR             | ERROR           |
      # one_predecessor      | ERROR       | ERROR     | case 1                | case 2            | sharing 1       |
      # multiple_predecessors| ERROR       |ERROR      | case 3                | case 4            | sharing 2       |
      def step_predictor(thread_id, anEntry, rank)
        case_parents = nil
        curr_ip = scaffold.catwalk[thread_id]
        if curr_ip
          case curr_ip.parents.size
          when 0 then case_parents = :no_parent
          when 1
            if curr_ip.parents[0].node.is_a?(Dendroid::Parsing::OrNode)
            case_parents = :one_or_parent
            else
              case_parents = :one_parent
            end
          else
            case_parents = :multiple_parents
          end
        else
          case_parents = :nil
        end

        case_predecessors = case anEntry.predecessors.size
        when 0 then :no_predecessor
        when 1 then :one_predecessor
        else
          :multiple_predecessors
        end

        case [case_predecessors, case_parents]
        when [:one_predecessor, :no_parent]
          predictor_1_1(thread_id, anEntry, rank, curr_ip)

        when [:one_predecessor, :one_parent]
          predictor_1_2(thread_id, anEntry, rank, curr_ip)

        when [:one_predecessor, :one_or_parent]
          predictor_1_3(thread_id, anEntry, rank, curr_ip)

        when [:one_predecessor, :multiple_parents]
          sharing_1(thread_id, anEntry, rank, curr_ip)

        when [:multiple_predecessors, :no_parent]
          predictor_2_1(thread_id, anEntry, rank, curr_ip)

        when [:multiple_predecessors, :one_parent]
          predictor_2_2(thread_id, anEntry, rank, curr_ip)

        when [:multiple_predecessors, :one_or_parent]
          predictor_2_3(thread_id, anEntry, rank, curr_ip)

        when [:multiple_predecessors, :multiple_parents]
          sharing_2(thread_id, anEntry, rank, curr_ip)
        else
          raise NotImplementedError, "Case #{[case_predecessors, case_parents]}"
        end
      end

      # [:one_predecessor, :no_parent]
      def predictor_1_1(thread_id, anEntry, _rank, ipoint)
        puts 'predictor_1_1'
        if ipoint.full?
          raise StandardError, 'Uncovered case'
        else
          chart_walker.enqueue(thread_id, anEntry, anEntry.predecessors[0])
        end
      end

      # [:one_predecessor, :one_parent]
      def predictor_1_2(thread_id, anEntry, rank, ipoint)
        puts 'predictor_1_2'
        if ipoint.full?
          raise StandardError, 'Uncovered case'
        else
          chart_walker.enqueue(thread_id, anEntry, anEntry.predecessors[0])
        end
      end

      # [:one_predecessor, :one_or_parent]
      def predictor_1_3(thread_id, anEntry, rank, ipoint)
        puts 'predictor_1_3'
        if ipoint.full?
          raise StandardError, 'Uncovered case'
        else
          # quadruplet = [thread_id, algo, prev_element, element]
          chart_walker.enqueue(thread_id, anEntry, anEntry.predecessors[0])
        end
      end

      # [:multiple_predecessors, :no_parent]
      # case l10, one token
      def predictor_2_1(thread_id, anEntry, _rank, _ipoint)
        puts 'predictor_2_1'
        if anEntry.predecessors.any? { |pred| pred.is_a? Dendroid::Recognizer::StartItem }
          scaffold.catwalk.delete(thread_id)
        else
          raise StandardError
        end
      end

      # [:multiple_predecessors, :one_parent]
      # case l10, two tokens
      # thread_id: 0
      # anEntry: A => . A a @ 0 ; predecessors: [A => . A a @ 0, . A]
      # rank: 0
      # ipoint: A => A a [0..1] ; parents: [A => A a [0..2]]
      def predictor_2_2(thread_id, anEntry, _rank, ipoint)
        puts 'predictor_2_2'
        if ipoint.full? && ipoint.match?(anEntry)
          scaffold.catwalk.delete(thread_id)
          par = ipoint.parents[0]
          scaffold.catwalk[par.thread] = par
          anEntry.predecessors.each do |pred|
            if par.match?(pred)
              chart_walker.enqueue(par.thread, anEntry, pred)
            end
          end

        else
          raise StandardError, 'Uncovered case'
        end
      end

      # [:multiple_predecessors, :one_or_parent]
      def predictor_2_3(thread_id, anEntry, _rank, ipoint)
        puts 'predictor_2_3'
        if ipoint.full? && ipoint.match?(anEntry)
          scaffold.catwalk.delete(thread_id)
          par = ipoint.parents[0]
          par.state.thread_completed(thread_id)
          if par.state.done?
            return if par.root?
          end

        else
          raise StandardError, 'Uncovered case'
        end
      end

      # [:one_predecessor, :multiple_parents]
      def sharing_1(thread_id, anEntry, _rank, ipoint)
        puts 'sharing_1'
        if ipoint.full?
          raise StandardError, 'Uncovered case'
        else
          chart_walker.enqueue(thread_id, anEntry, anEntry.predecessors[0])
        end
      end

      [:multiple_predecessors, :multiple_parents]
      def sharing_2(thread_id, anEntry, _rank, ipoint)
        puts 'sharing_2'
        if ipoint.full?
          parents_by_thread = ipoint.parents.group_by { |par| par.thread }
          if parents_by_thread.size == 1 # One single thread ? ...
            par_list = sort_innermost(parents_by_thread.values[0]).take(1)

          else
            first_by_thread = parents_by_thread.values.map do |arr|
              if arr.size == 1
                arr[0]
              else
                sort_innermost(arr).first
              end
            end
            par_list = sort_innermost(first_by_thread)
          end
          scaffold.catwalk.delete(thread_id)

          new_ipoints = par_list.map { |par| par.rollup }.flatten.uniq
          return if new_ipoints.empty?

          preds = anEntry.predecessors.dup
          new_ipoints.each do |ip|
            preds.each do |prd|
              next unless ip.match?(prd)

              scaffold.catwalk[ip.thread] = ip
              chart_walker.enqueue(ip.thread, anEntry, prd)
            end
          end
        else
          raise StandardError, 'Uncovered case'
        end
      end

      def step_predictor_old(thread_id, anEntry, rank)
        candidates = []
        curr_ip = scaffold.catwalk[thread_id]
        if curr_ip.nil?
          return if anEntry.predecessors.any? { |pred| pred.is_a?(Dendroid::Recognizer::StartItem) }

          raise StandardError, "step_predictor: Cannot find ipoint for thread #{thread_id} on catwalk."
        elsif curr_ip.is_a? Array
          raise StandardError, "step_predictor: Found multiple ipoints for thread #{thread_id} on catwalk."
        end
        is_full = false
        if curr_ip.full?
          is_full = true
          if curr_ip.match?(anEntry)
            # l10, one token: anEntry: A => . A a @ 0, catwalk: {0=>A => A a [0..1]}
            candidates << curr_ip
          else
            # l18, three tokens: anEntry: S => X . S a @ 0, pre-catwalk: {0=>S => X S a [0..3]}
            # Remark X symbol is nul
            raise StandardError # Uncovered case
          end
        elsif curr_ip.same_prediction?(anEntry, rank)
          puts "curr_ip #{curr_ip} not full; same_prediction? T with #{anEntry}"
          candidates << curr_ip
        elsif curr_ip.match?(anEntry)
          puts "curr_ip #{curr_ip} not full; match? T with #{anEntry}"
          candidates << curr_ip
        else
          raise StandardError # Uncovered case
        end

        # Update catwalk with parent ipoints
        candidates.each do |curr_ip|
          curr_parents = curr_ip.parents
          case curr_parents.size
          when 0
            if anEntry.is_a?(Dendroid::Recognizer::StartItem)
              return
            elsif anEntry.predecessors.any? { |pred| pred.is_a?(Dendroid::Recognizer::StartItem) }
              # TODO: enqueue StartItem predecessor only
              # case: l10, one token. i = 3, anEntry: A => . A a @ 0, predecessors: [A => . A a @ 0, .A]
              finish = anEntry.predecessors.find { |pred| pred.is_a?(Dendroid::Recognizer::StartItem) }
              chart_walker.enqueue(thread_id, anEntry.algo, anEntry, finish)
              return
            else
              # case: l11, one token. i = 3, anEntry: A => . A a @ 0, predecessors: [A => . A a @ 0, .A]
              preds = anEntry.predecessors
              preds.each do |prd|
                chart_walker.enqueue(thread_id, anEntry.algo, anEntry, prd)
              end
            end

          when 1
            parent = curr_parents[0]
            if is_full && parent.node.is_a?(Dendroid::Parsing::OrNode)
              scaffold.catwalk.delete(thread_id)
              parent.state.thread_completed(thread_id)
              if parent.state.done? && !parent.parents.empty?
                parent.parents.each do |grandma|
                  scaffold.catwalk[grandma.thread] = grandma
                  anEntry.predecessors.each do |pred|
                    next if pred.is_a?(Dendroid::Recognizer::StartItem)
                    # if parent.match?(pred)
                      chart_walker.enqueue(grandma.thread, anEntry.algo, anEntry, pred)
                    # end
                  end
                end
              end
            else
              scaffold.catwalk[thread_id] = parent if is_full
              anEntry.predecessors.each do |pred|
                next if pred.is_a?(Dendroid::Recognizer::StartItem)
                if !is_full || scaffold.catwalk[thread_id].match?(pred)
                  chart_walker.visit_queue.enqueue(thread_id, anEntry.algo, anEntry, pred)
                end
              end
            end
            return

          else # Multiple parents ...
            if curr_parents.all? { |par| par.thread == thread_id } # Multiple parents, same thread ...
              # Shared node ... if in same thread and all full, keep topmost parent
              # case: l18, three tokens. i = 11, anEntry: S => . X S a @ 0, predecessors: [S => X . S a @ 0, .S]
              #   curr_parents: [S => X S a [0..2], S => X S a [0..3]]
              # This case happens in case of left hidden recursive rules
              # TODO: keep topmost parent OR see next line
              # TODO RULE: when sharing a node in same thread, don't add a parent to shared ipoint
              direct_parent = sort_innermost(curr_parents)[0]
              scaffold.catwalk[thread_id] = direct_parent

            else
              if curr_ip.full?
                # scaffold.catwalk.delete(thread_id)
                # copies = curr_ip.dup_except(thread_id)
                # copies.each { |par| scaffold.catwalk[par.thread] = par }
                # parent_in_thread = curr_ip.parents.find { |par| par.thread == thread_id }
                # scaffold.catwalk[thread_id] = parent_in_thread
                curr_ip.parents.each do |par|
                  scaffold.catwalk[par.thread] = par
                  anEntry.predecessors.each do |pred|
                    if par.match?(pred)
                      chart_walker.enqueue(par.thread, anEntry.algo, anEntry, pred)
                    end
                  end
                end
              else
                anEntry.predecessors.each do |pred|
                  next if pred.is_a?(Dendroid::Recognizer::StartItem)
                  # if curr_ip.match?(pred)
                    chart_walker.enqueue(thread_id, anEntry.algo, anEntry, pred)
                  # end
                end
              end
            end
          end
        end
      end

      def step_scanner(thread_id, anEntry, rank)
        if scaffold.terminal_ipoint_at(rank)
          # TODO: implement sharing
          raise StandardError
        end
        symb = anEntry.dotted_item.next_symbol
        child_node = chart_walker.new_terminal_node(symb)
        ipoint = scaffold.add_terminal_node(thread_id, anEntry, rank, child_node)

        if anEntry.algo == :predictor && anEntry.predecessors.size > 1
          to_enqueue = false
          anEntry.predecessors.each do |pred|
            ancestors = ipoint.predicted_ancestors(pred, rank)
            ancestors.each do |anc|
              chart_walker.enqueue_entry(anc.thread, pred, anEntry,:predictor)
            end
            to_enqueue = true
          end
          scaffold.rollup(ipoint) if to_enqueue

        else
          scaffold.rollup(ipoint) if ipoint.full?
          pred = anEntry.predecessors[0]
          chart_walker.enqueue_predecessors_of(thread_id, anEntry) unless pred.is_a?(Dendroid::Recognizer::StartItem)
        end
      end

      def step_completer(thread_id, anEntry, rank, prev_entry)
        if anEntry.predecessors.size == 1
          if anEntry.dotted_item.final_pos?
            child_node = chart_walker.new_and_node(anEntry, rank)
            child_ip = scaffold.add_and_node2(thread_id, anEntry, rank, child_node)
          end
          if child_ip&.shared?
            scaffold.catwalk.delete(thread_id)
          else
            chart_walker.enqueue_predecessors_of(thread_id, anEntry)
          end
        else
          # Entry has multiple predecessors
          ambiguity_detected(thread_id, anEntry, prev_entry, rank)
        end
      end

      def step_empty_rule(thread_id, anEntry, rank)
        # Empty RHS a mix of :completer and :predictor handling
        child_node = chart_walker.new_and_node(anEntry, rank)
        child_ip = scaffold.add_leaf_node(thread_id, anEntry, rank, child_node)

        # Response to empty rule is similar to predictor handling
        predecessors = compatible_predecessors(anEntry, child_ip)
        predecessors.each do |pred|
          if pred.is_a? Dendroid::Recognizer::StartItem
            algo = :completer
          elsif pred.dotted_item.initial_pos?
            algo = :predictor
          elsif pred.dotted_item.prev_symbol.is_a? Dendroid::Syntax::Terminal
            algo = :completer
          else
            algo = :completer
          end
          chart_walker.enqueue_entry(thread_id, pred, anEntry, algo)
        end
      end

      def compatible_predecessors(anEntry, iPoint)
        preds = []
        case iPoint.parents.size
        when 0
          preds = anEntry.predecessors.select { |prd| prd.is_a? Dendroid::Recognizer::StartItem }

        when 1
          anEntry.predecessors.each do |prd|
            next unless iPoint.parents[0].match?(prd)

            preds << prd
          end

        else
          thread2parents = iPoint.parents.group_by { |par| par.thread }
          thread2parents.each_pair do |thread, parents|
            if parents.size == 1
              anEntry.predecessors.each do |prd|
                next unless parents[0].match?(prd)

                preds << prd
              end
            else
              sorted = parents.sort { |a, b| b.origin <=> a.origin }
              lower = sorted[0].origin
              filtered_parents = sorted.select { |ip| ip.origin == lower }
              candidate = filtered_parents[0]
              if candidate.full?
                scaffold.rollup(candidate)
                curr_ip = scaffold.catwalk[thread]
              else
                scaffold.catwalk[thread] = candidate
                curr_ip = candidate
              end

              anEntry.predecessors.each do |prd|
                if curr_ip
                  next unless curr_ip.match?(prd)

                  preds << prd
                elsif prd.is_a? Dendroid::Recognizer::StartItem
                  preds << prd
                end
              end
            end
          end
        end

        preds
      end

      def ambiguity_detected(thread_id, anEntry, prev_entry, rank)
        arity = anEntry.predecessors.count
        or_node = OrNode.new(anEntry.lhs, anEntry.origin, rank, arity)
        or_ip = scaffold.add_or_node(thread_id, anEntry, rank, or_node)
        children = []
        anEntry.predecessors.each_with_index do |pred, i|
          child_node = chart_walker.new_and_node(anEntry, rank)
          child_node.ordering = i
          child_ip = or_ip.add_child_node(child_node)
          child_ip.thread = chart_walker.new_thread_id
          child_ip.expected_predecessor = pred
          scaffold.map(child_node, child_ip)
          children << child_ip
          proxy = EItemProxy.new(anEntry.predecessors[i], i, false)
          chart_walker.enqueue_entry(child_ip.thread, proxy, anEntry,:completer)
        end
        scaffold.replace_by_children(or_ip, children)
      end

      def dequeue
        (_t_id, _algo, _prev_visitee, visitee) = chart_walker.visit_queue.peek
        if visitee.is_a?(Dendroid::Recognizer::StartItem) && chart_walker.visit_queue.size > 1
          (thread_id, algo, prev_visitee, visitee) = chart_walker.dequeue
          chart_walker.visit_queue.enqueue(thread_id, visitee, prev_visitee, algo) # Move StartItem at end of queue
        end

        chart_walker.dequeue
      end

      def sort_innermost(ipoints)
        return ipoints if ipoints.size < 2

        ipoints.sort do |a, b|
          if a.is_a?(Dendroid::Recognizer::StartItem)
            +1
          elsif b.is_a?(Dendroid::Recognizer::StartItem)
            -1
          else
            comp = a.node.extent.innermost(b.node.extent)
            if comp.zero?
              if a.parents[0] == b
                -1
              elsif b.parents[0] == a
                +1
              else
                0 # Indeterminate order
              end
            else
              comp
            end
          end
        end
      end
    end # class
  end # module
end # module
