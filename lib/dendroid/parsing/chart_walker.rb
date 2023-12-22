# frozen_string_literal: true

require_relative 'walk_progress'

module Dendroid
  module Parsing
    class ChartWalker
      attr_reader :chart
      attr_reader :last_item

      # rubocop: disable Metrics/AbcSize
      # rubocop: disable Metrics/CyclomaticComplexity
      # rubocop: disable Metrics/PerceivedComplexity

      def initialize(theChart)
        @chart = theChart
      end

      def walk(start_item)
        curr_rank = chart.size - 1

        parents = []
        progress = WalkProgress.new(curr_rank, start_item, parents)
        paths = [progress]

        if start_item.predecessors.size > 1
          # Create n times start_item as predecessors, then for each path initialize to its unique own predecessor
          forerunners = disambiguate(progress, start_item.predecessors)
          if forerunners.size == 1
            parents << AndNode.new(start_item, curr_rank)
          else
            preds = sort_predecessors(forerunners)
            if start_item.rule.rhs.size == 1
              parents << AndNode.new(start_item, curr_rank)
              progress.push_or_node(start_item.origin, preds.size)
            else
              parents << OrNode.new(start_item.lhs, start_item.origin, curr_rank, preds.size)
            end
            progress.curr_item = start_item
            fork(progress, paths, preds)
          end
        else
          parents << AndNode.new(start_item, curr_rank)
        end
        token2node = {}
        entry2node = {}
        sharing = {}
        or_nodes_crossed = {}

        loop do # Iterate over rank values
          pass = :primary
          loop do # Iterate over paths until all are ready for previous rank
            paths.each do |prg|
              next if prg.state == :Complete || prg.state == :Delegating
              next if pass == :secondary && prg.state == :Waiting

              step_back(prg, paths, token2node, entry2node, sharing, or_nodes_crossed)
            end
            # TODO: handle path removal
            break if paths.none? { |pg| pg.state == :Running || pg.state == :Forking }

            pass = :secondary
          end
          break if paths.all? { |prg| prg.state == :Complete }

          entry2node.clear
        end

        parents[0]
      end

      def step_back(walk_progress, paths, token2node, entry2node, sharing, or_nodes_crossed)
        loop do
          case walk_progress.state
          when :Waiting, :New
            predecessors = predecessors_of(walk_progress.curr_item, walk_progress.parents)
            last_parent = walk_progress.parents.last
            if sharing.include? last_parent
              delegating = sharing[last_parent]
              unless delegating.include? walk_progress
                delegating.each do |dlg|
                  dlg.curr_rank = walk_progress.curr_rank
                  dlg.curr_item = walk_progress.curr_item
                  dlg.state = :Waiting
                end
                sharing.delete(last_parent)
              end
            end
            walk_progress.state = :Running

          when :Running
            predecessors = predecessors_of(walk_progress.curr_item, walk_progress.parents)

          when :Forking
            # predecessors = [walk_progress.curr_item]
            predecessors = [walk_progress.predecessor]
            walk_progress.predecessor = nil
            walk_progress.state = :Running
          end

          if predecessors.empty?
            walk_progress.state = :Complete
            break
          end

          case walk_progress.curr_item.algo
          when :completer
            completer_backwards(walk_progress, paths, entry2node, sharing, predecessors)
            break if walk_progress.state == :Delegating

          when :scanner
            curr_token = chart.tokens[walk_progress.curr_rank - 1]
            if token2node.include? curr_token
              walk_progress.add_child_node(token2node[curr_token])
              walk_progress.curr_rank -= 1
            else
              new_node = walk_progress.add_terminal_node(chart.tokens[walk_progress.curr_rank - 1])
              token2node[curr_token] = new_node
            end
            if predecessors.size == 1
              walk_progress.curr_item = predecessors[0]
              walk_progress.state = :Waiting
              break
            else
              # TODO: challenge assumption single predecessor
              raise StandardError
            end

          when :predictor
            unless walk_progress.parents.last.partial?
              last_parent = walk_progress.parents.pop
              if sharing.include? last_parent
                delegating = sharing[last_parent]
                unless delegating.include? walk_progress
                  delegating.each do |dlg|
                    dlg.curr_rank = walk_progress.curr_rank
                    dlg.curr_item = walk_progress.curr_item
                    dlg.state = :Running
                  end
                  sharing.delete(last_parent)
                end
              end
              if last_parent.is_a?(OrNode)
                if or_nodes_crossed.include?(last_parent)
                  walk_progress.state = :Complete
                  break
                else
                  or_nodes_crossed[last_parent] = true
                end
              end
            end
            index_empty = predecessors.find_index { |entry| entry.dotted_item.empty? }
            if index_empty
              entry_empty = predecessors.delete_at(index_empty)
              walk_progress.add_node_empty(entry_empty)
              raise StandardError unless predecessors.empty? # Uncovered case

              walk_progress.curr_item = entry_empty
              next
            end
            if predecessors.size == 1
              walk_progress.curr_item = predecessors[0]
            else
              # curr_item has multiple predecessors from distinct rules
              # look in lineage the latest entry that matches one of the ancestors AND
              # has a free slot for the current symbol
              matches = walk_progress.match_parent?(predecessors, true)
              if matches.empty?
                walk_progress.state = :Complete
                break
              end
              (matching_pred, stack_offset) = matches.first
              walk_progress.curr_item = matching_pred
              unless stack_offset.zero?
                removed = walk_progress.parents.pop(stack_offset)
                if removed.is_a?(Array)
                  or_nodes = removed.select { |entry| entry.is_a?(OrNode) }
                  unless or_nodes.empty?
                    or_nodes.reverse_each do |or_nd|
                      if or_nodes_crossed.include?(or_nd)
                        walk_progress.state = :Complete
                        break
                      else
                        or_nodes_crossed[or_nd] = true
                      end
                    end
                    break if walk_progress.state == :Complete

                  end
                elsif removed.is_a?(OrNode)
                  if or_nodes_crossed.include?(removed)
                    walk_progress.state = :Complete
                    break
                  else
                    or_nodes_crossed[removed] = true
                  end
                end
              end
            end
          else
            raise StandardError
          end
        end

        walk_progress
      end

      def disambiguate(_progress, predecessors)
        predecessors
      end

      def sort_predecessors(predecessors)
        predecessors
      end

      def predecessors_of(anEItem, parents)
        # Rule: if anEItem has itself as predecessor AND parents contains
        # only a start item, then remove anEItem from its own predecessor(s).
        if (parents.size == 1) && anEItem.predecessors.include?(anEItem)
          # raise StandardError unless parents[0].match(anEItem)
          unless parents[0].match(anEItem)
            raise StandardError

          end
          preds = anEItem.predecessors.dup
          preds.delete(anEItem)
          preds
        else
          anEItem.predecessors
        end
      end

      def completer_backwards(walk_progress, paths, entry2node, sharing, predecessors)
        # Trying to remove some predecessors with some disambiguation technique
        forerunners = disambiguate(walk_progress, predecessors)

        if forerunners.size == 1
          pred = forerunners[0]
          if entry2node.include? pred
            shared_node = entry2node[pred]
            if sharing.include? shared_node
              sharing[shared_node] << walk_progress
            else
              sharing[shared_node] = [walk_progress]
            end
            walk_progress.add_child_node(shared_node)
            walk_progress.parents.push(shared_node)
            walk_progress.state = :Delegating

          elsif pred.predecessors.size == 1
            new_node = walk_progress.push_and_node(pred)
            walk_progress.curr_item = pred
            entry2node[pred] = new_node
          else
            pre_forerunners = disambiguate(walk_progress, pred.predecessors)
            index_empty = pre_forerunners.find_index { |entry| entry.dotted_item.empty? }
            if index_empty
              entry_empty = pre_forerunners.delete_at(index_empty)
              walk_progress.add_node_empty(entry_empty)
              walk_progress.curr_item = entry_empty.predecessors[0] # Assuming only one predecessor
            end
            if pre_forerunners.size == 1
              pred = forerunners[0]
              new_node = walk_progress.push_and_node(pre_forerunners[0])
              walk_progress.curr_item = pred
              entry2node[pred] = new_node
            else
              prepreds = sort_predecessors(pre_forerunners)
              new_node = walk_progress.push_or_node(pred.origin, prepreds.size)
              walk_progress.curr_item = pred
              entry2node[pred] = new_node
              fork(walk_progress, paths, prepreds)
            end
          end
        else
          # AMBIGUITY: multiple valid predecessors
          preds = sort_predecessors(forerunners)
          walk_progress.push_or_node(preds)
          fork(walk_progress, paths, preds)
        end
      end

      def fork(walk_progress, paths, sorted_predecessors)
        progs = [walk_progress]
        walk_progress.fork(sorted_predecessors[0])
        sorted_predecessors[1..].each do |prd|
          alternate = walk_progress.dup
          alternate.fork(prd)
          paths << alternate
          progs << alternate
        end

        progs.each { |pg| pg.push_and_node(pg.curr_item) }
      end
    end # class

    # rubocop: enable Metrics/AbcSize
    # rubocop: enable Metrics/CyclomaticComplexity
    # rubocop: enable Metrics/PerceivedComplexity
  end # module
end # module
