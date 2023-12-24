# frozen_string_literal: true

require_relative 'walk_progress'

module Dendroid
  module Parsing
    # Keeps track of the visited chart entries in order to implement
    # the sharing of parse nodes.
    class WalkContext
      # Mapping chart item => ParseNode for the current item set.
      # @return [Hash{Dendroid::Recognizer::EItem => ParseNode}]
      attr_reader :entry2node

      # @return [Hash{Syntax::Token => TerminalNode}]
      attr_reader :token2node

      # @return [Hash{OrNode => true}]
      attr_reader :or_nodes_crossed

      # @return [Hash{Parsing::ParseNode => Array<Dendroid::Parsing::WalkProgress>}]
      attr_reader :sharing

      def initialize
        @entry2node = {}
        @token2node = {}
        @or_nodes_crossed = {}
        @sharing = {}
      end

      # Was the given chart entry already encountered?
      # @param anEItem [Dendroid::Recognizer::EItem] chart entry to test
      def known_entry?(anEItem)
        entry2node.include?(anEItem)
      end

      # Make the given chart entry the new current item and
      # mark its related node as known (visited)
      # @param walk_progress [Dendroid::Parsing::WalkProgress]
      # @param anEItem [Dendroid::Recognizer::EItem]
      # @param aNode [Dendroid::Parsing::ParseNode]
      def advance(walk_progress, anEItem, aNode)
        walk_progress.curr_item = anEItem
        entry2node[anEItem] = aNode
      end

      # For a given token, make a terminal node a child of the current parent.
      # @param walk_progress [Dendroid::Parsing::WalkProgress]
      # @param token [Dendroid::Lexical::Token]
      def add_terminal_node(walk_progress, token)
        if token2node.include? token
          walk_progress.add_child_node(token2node[token])
          walk_progress.curr_rank -= 1
        else
          new_node = walk_progress.add_terminal_node(token)
          token2node[token] = new_node
        end
      end

      # Add an and node as a child of current parent of given walk progress
      # @param walk_progress [Dendroid::Parsing::WalkProgress]
      # @param anEItem [Dendroid::Recognizer::EItem]
      def add_and_node(walk_progress, anEItem)
        new_node = walk_progress.push_and_node(anEItem)
        advance(walk_progress, anEItem, new_node)
      end

      # Check whether the given node was already seen.
      # If yes, set the state of the walk progress to Complete
      # @param walk_progress [Dendroid::Parsing::WalkProgress]
      # @param anOrNode [Dendroid::Parsing::OrNode]
      # @return [Boolean] true if the walk progress is in Complete state
      def join_or_node(walk_progress, anOrNode)
        already_crossed = or_nodes_crossed.include?(anOrNode)
        if already_crossed
          walk_progress.state = :Complete
        else
          or_nodes_crossed[anOrNode] = true
        end

        already_crossed
      end

      # @param anEItem [Dendroid::Recognizer::EItem]
      # @param walk_progress [Dendroid::Parsing::WalkProgress]
      def start_delegation(anEItem, walk_progress)
        shared_node = entry2node[anEItem]
        if sharing.include? shared_node
          sharing[shared_node] << walk_progress
        else
          sharing[shared_node] = [walk_progress]
        end
        walk_progress.add_child_node(shared_node)
        walk_progress.parents.push(shared_node)
        walk_progress.state = :Delegating
      end

      # If the given node is shared by other WalkProgress, update them
      # with the advancement of the provided WalkProgress & dissolve the delegation
      # @param aNode [Dendroid::Parsing::ParseNode]
      # @param walk_progress [Dendroid::Parsing::WalkProgress]
      # @param desired_state [Symbol] New state of the delegating walk progresses
      def stop_delegation(aNode, walk_progress, desired_state)
        if sharing.include? aNode
          delegating = sharing[aNode]
          unless delegating.include? walk_progress
            delegating.each do |dlg|
              dlg.curr_rank = walk_progress.curr_rank
              dlg.curr_item = walk_progress.curr_item
              dlg.state = desired_state
            end
            sharing.delete(aNode)
          end
        end
      end

      # Remove multiple parent from the parent stack of provided
      # walk progress. If one of the removed node is an OrNode
      # and it was already encountered, then the walk progress is deemed complete.
      # @param walk_progress [Dendroid::Parsing::WalkProgress]
      # @param count [Integer] the number of parents to pop; must be greater than one
      def pop_multiple_parents(walk_progress, count)
        removed = walk_progress.parents.pop(count)
        if removed.is_a?(Array)
          or_nodes = removed.select { |entry| entry.is_a?(OrNode) }
          unless or_nodes.empty?
            or_nodes.reverse_each do |or_nd|
              break if join_or_node(walk_progress, or_nd)
            end
          end
        elsif removed.is_a?(OrNode)
          join_or_node(walk_progress, removed)
        end
      end
    end # class

    # A chart walker visits a chart produced by the Earley recognizer.
    # It visits the chart backwards: it begins with the chart entries
    # representing a successful recognition then walks to the predecessor
    # entries and so on.
    class ChartWalker
      # @return [Dendroid::Recognizer::Chart] The chart to visit
      attr_reader :chart

      # @param theChart [Dendroid::Recognizer::Chart] The chart to visit
      def initialize(theChart)
        @chart = theChart
      end

      # @param start_item [Dendroid::Recognizer::EItem] The chart entry to visit first.
      def walk(start_item)
        curr_rank = chart.size - 1
        progress = WalkProgress.new(curr_rank, start_item, [])
        paths = [progress]
        visit_start_item(progress, paths, start_item)
        ctx = WalkContext.new

        loop do # Iterate over rank values
          pass = :primary
          loop do # Iterate over paths until all are ready for previous rank
            all_paths_advance(ctx, paths, pass)
            # TODO: handle path removal
            break if paths.none? { |pg| pg.state == :Running || pg.state == :Forking }

            pass = :secondary
          end
          break if paths.all? { |prg| prg.state == :Complete }

          ctx.entry2node.clear
        end

        progress.parents[0]
      end

      # Start the visit of with the success (accept) chart entry.
      # Build the root node(s) of parse tree/forest
      # @param progress [Dendroid::Parsing::WalkProgress]
      # @param paths [Array<Dendroid::Parsing::WalkProgress>]
      # @param start_item [Dendroid::Recognizer::EItem]
      def visit_start_item(progress, paths, start_item)
        preds = disambiguate_predecessors(progress, start_item.predecessors)
        if preds.size == 1
          progress.push_and_node(start_item)
        else
          # Multiple predecessors...
          if start_item.rule.rhs.size == 1
            progress.push_and_node(start_item)
            progress.push_or_node(start_item.origin, preds.size)
          else
            progress.parents << OrNode.new(start_item.lhs, start_item.origin, progress.curr_rank, preds.size)
          end
          progress.curr_item = start_item
          fork(progress, paths, preds)
        end
      end

      # Iterate over each path, if allowed perform a step back
      # @param ctx [Dendroid::Parsing::WalkContext]
      # @param paths [Array<Dendroid::Parsing::WalkProgress>]
      # @param pass [Symbol] one of: :primary, :secondary
      def all_paths_advance(ctx, paths, pass)
        paths.each do |prg|
          next if prg.state == :Complete || prg.state == :Delegating
          next if pass == :secondary && prg.state == :Waiting

          step_back(prg, ctx, paths)
        end
      end

      # For the given walk_progress, perform the visit of predecessors of
      # the chart entry designated as the current one.
      # @param walk_progress [Dendroid::Parsing::WalkProgress]
      # @param context [Dendroid::Parsing::WalkContext]
      def step_back(walk_progress, context, paths)
        loop do
          predecessors = predecessors_for_state(context, walk_progress)
          break if walk_progress.state == :Complete

          case walk_progress.curr_item.algo
          when :completer
            completer_backwards(walk_progress, context, paths, predecessors)
            break if walk_progress.state == :Delegating

          when :scanner
            curr_token = chart.tokens[walk_progress.curr_rank - 1]
            scanner_backwards(walk_progress, context, predecessors, curr_token)
            break

          when :predictor
            unless walk_progress.parents.last.partial?
              last_parent = walk_progress.parents.pop
              context.stop_delegation(last_parent, walk_progress, :Running)
              if last_parent.is_a?(OrNode)
                break if context.join_or_node(walk_progress, last_parent)
              end
            end
            predictor_backwards(walk_progress, context, predecessors)
            break if walk_progress.state == :Complete
          else
            raise StandardError
          end
        end

        walk_progress
      end

      # Determine predecessors of current item according the walk progess state.
      # If needed, update also the state.
      # @param context [Dendroid::Parsing::WalkContext]
      # @param walk_progress [Dendroid::Parsing::WalkProgress]
      def predecessors_for_state(context, walk_progress)
        case walk_progress.state
        when :Waiting, :New
          predecessors = predecessors_of(walk_progress.curr_item, walk_progress.parents)
          last_parent = walk_progress.parents.last
          context.stop_delegation(last_parent, walk_progress, :Waiting)
          walk_progress.state = :Running

        when :Running
          predecessors = predecessors_of(walk_progress.curr_item, walk_progress.parents)

        when :Forking
          predecessors = [walk_progress.predecessor]
          walk_progress.predecessor = nil
          walk_progress.state = :Running
        end

        walk_progress.state = :Complete if predecessors.empty?
        predecessors
      end

      # Check whether given chart entry has multiple predecessorss.
      # If yes, then apply disambiguation to reduce the number of valid predecessors
      # If there are still multiple predecessors, then sort them.
      # @param _progress [Dendroid::Parsing::WalkProgress] Unused
      # @param predecessors [Array<Dendroid::Recognizer::EItem>]
      # @return [Array<Dendroid::Recognizer::EItem>]
      def disambiguate_predecessors(_progress, predecessors)
        if predecessors.size > 1
          sort_predecessors(predecessors)
        else
          predecessors
        end
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

      def scanner_backwards(walk_progress, context, predecessors, curr_token)
        context.add_terminal_node(walk_progress, curr_token)
        if predecessors.size == 1
          walk_progress.curr_item = predecessors[0]
          walk_progress.state = :Waiting
        else
          # TODO: challenge assumption single predecessor
          raise StandardError
        end
      end

      def completer_backwards(walk_progress, context, paths, predecessors)
        # Trying to remove some predecessors with some disambiguation technique
        forerunners = disambiguate_predecessors(walk_progress, predecessors)

        if forerunners.size == 1
          pred = forerunners[0]
          if context.known_entry? pred
            context.start_delegation(pred, walk_progress)
          elsif pred.predecessors.size == 1
            context.add_and_node(walk_progress, pred)
          else
            pre_forerunners = disambiguate_predecessors(walk_progress, pred.predecessors)
            index_empty = pre_forerunners.find_index { |entry| entry.dotted_item.empty? }
            if index_empty
              entry_empty = pre_forerunners.delete_at(index_empty)
              walk_progress.add_node_empty(entry_empty)
              walk_progress.curr_item = entry_empty.predecessors[0] # Assuming only one predecessor
            end
            if pre_forerunners.size == 1
              new_node = walk_progress.push_and_node(pre_forerunners[0])
              context.advance(walk_progress, pred, new_node)
            else
              new_node = walk_progress.push_or_node(pred.origin, pre_forerunners.size)
              context.advance(walk_progress, pred, new_node)
              fork(walk_progress, paths, pre_forerunners)
            end
          end
        else
          # AMBIGUITY: multiple valid predecessors
          walk_progress.push_or_node(forerunners)
          fork(walk_progress, paths, forerunners)
        end
      end

      def predictor_backwards(walk_progress, context, predecessors)
        index_empty = predecessors.find_index { |entry| entry.dotted_item.empty? }
        if index_empty
          entry_empty = predecessors.delete_at(index_empty)
          walk_progress.add_node_empty(entry_empty)
          raise StandardError unless predecessors.empty? # Uncovered case

          walk_progress.curr_item = entry_empty
          return
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
          else
            (matching_pred, stack_offset) = matches.first
            walk_progress.curr_item = matching_pred
            unless stack_offset.zero?
              context.pop_multiple_parents(walk_progress, stack_offset)
            end
          end
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
  end # module
end # module
