# frozen_string_literal: true

require_relative 'insertion_point'

module Dendroid
  module Parsing
    class Scaffold
      # @return [Hash {Integer => InsertionPoint}] Mapping thread id to current insertion point.
      attr_reader :catwalk

      attr_reader :root
      attr_reader :terminal_points

      def initialize(tokenCount)
        @catwalk = {}
        @root = nil
        @terminal_points = Array.new(tokenCount)
        @node_lit2ip = {}
      end

      def catwalk_to_text
        result = +''
        @catwalk.each_pair do |tr_id, ip|
          result << "#{tr_id}=>#{ip},"
        end

        result
      end

      def terminal_ipoint_at(aRank)
        terminal_points.at(aRank)
      end

      def lift(entry, rank)
        indices = matching_indices(entry, rank)
        return false if indices.empty?

        indices.each do |i|
          curr_parents = catwalk[i].parents
          case curr_parents.size
          when 0
            raise StandardError unless entry.is_a?(Dendroid::Recognizer::StartItem)

          when 1
            # TODO: if parent already present
            catwalk[i] = curr_parents[0]

          else
            # TODO: if one parent already present
            catwalk.delete_at(i)
            catwalk.concat(curr_parents)
          end
        end

        true
      end

      def rollup(ipoint, flag = true)
        return if ipoint.root?

        catwalk.delete(ipoint.thread)
        ipoint.parents.each do |par|
          if par.full? && flag
            rollup(par, false) unless par.root?
          else
            catwalk[par.thread] = par
          end
        end
      end

      def add_terminal_node(thread_id, entry, rank, node)
        ipoints = expecting_ipoints(thread_id, entry, rank)
        raise StandardError if ipoints.empty?

        curr_ip = ipoints.shift
        child_ip = curr_ip.add_child_node(node)
        terminal_points[rank] = child_ip

        ipoints.each do |ip|
          child_ip.share_with(ip)
        end

        child_ip
      end

      def build_ipoint(thread_id, parent, node)
        new_state =  node.is_a?(Dendroid::Parsing::OrNode) ? Conjunction.new(node.children.size) : PointState.new
        InsertionPoint.new(thread_id, parent, node, new_state)
      end

      # def add_and_node(thread_id, entry, prev_entry, rank, node)
      #   return set_root(thread_id, node) if root.nil?
      #
      #   indices = match_indices(entry, prev_entry, rank)
      #   if indices.empty?
      #     if entry.is_a?(EItemProxy)
      #     return
      #     else
      #       raise StandardError
      #     end
      #   end
      #
      #   node_str = node.to_s
      #   shared_ip = @node_lit2ip[node_str]
      #   if shared_ip
      #     child_ip = shared_ip
      #     catwalk << shared_ip unless catwalk.include? shared_ip
      #   else
      #     parent_idx = indices.shift
      #     curr_ip = catwalk[parent_idx]
      #     child_ip = curr_ip.add_child_node(node)
      #     @node_lit2ip[node_str] = child_ip
      #     catwalk[parent_idx] = child_ip
      #   end
      #
      #   indices.each do |i|
      #     curr_ip = catwalk[i]
      #     child_ip.share_with(curr_ip)
      #     catwalk.delete_at(i)
      #   end
      #
      #   child_ip
      # end

      def add_and_node2(thread_id, entry, rank, node)
        return set_root(thread_id, node) if root.nil?

        ipoints = expecting_ipoints(thread_id, entry, rank)
        if ipoints.empty?
          if entry.is_a?(EItemProxy)
            return
          else
            raise StandardError
          end
        end

        # Check whether same node was already in use ...
        node_str = node.to_s
        shared_ip = @node_lit2ip[node_str]

        if shared_ip
          child_ip = shared_ip
          # Reminder: a node may not appear more than once on catwalk
          catwalk[thread_id] = shared_ip unless catwalk.has_value? shared_ip
        else
          curr_ip = ipoints.shift
          child_ip = curr_ip.add_child_node(node)
          @node_lit2ip[node_str] = child_ip

          # Make child ip the new current one unless it's an empty rule
          catwalk[thread_id] = child_ip unless node.rule.alternatives[node.alt_index].empty?

        end

        ipoints.each { |ip| child_ip.share_with(ip) }

        child_ip

        #  OLD
        # indices = match_indices(entry, prev_entry, rank)
        # if indices.empty?
        #   if entry.is_a?(EItemProxy)
        #     return
        #   else
        #     raise StandardError
        #   end
        # end
        #
        # node_str = node.to_s
        # shared_ip = @node_lit2ip[node_str]
        # if shared_ip
        #   child_ip = shared_ip
        #   catwalk << shared_ip unless catwalk.include? shared_ip
        # else
        #   parent_idx = indices.shift
        #   curr_ip = catwalk[parent_idx]
        #   child_ip = curr_ip.add_child_node(node)
        #   @node_lit2ip[node_str] = child_ip
        #   catwalk[parent_idx] = child_ip
        # end
        #
        # indices.each do |i|
        #   curr_ip = catwalk[i]
        #   child_ip.share_with(curr_ip)
        #   catwalk.delete_at(i)
        # end
        #
        # child_ip
      end

      # def add_empty_node(entry, rank, node)
      #   return set_root(node) if root.nil?
      #
      #   indices = matching_indices(entry, rank)
      #   raise StandardError if indices.empty?
      #
      #   node_str = node.to_s
      #   shared_ip = @node_lit2ip[node_str]
      #   if shared_ip
      #     child_ip = shared_ip
      #   else
      #     parent_idx = indices.shift
      #     curr_ip = catwalk[parent_idx]
      #     child_ip = curr_ip.add_child_node(node)
      #     @node_lit2ip[node_str] = child_ip
      #   end
      #
      #   indices.each do |i|
      #     curr_ip = catwalk[i]
      #     child_ip.share_with(curr_ip)
      #   end
      # end

      def add_leaf_node(thread_id, entry, rank, node)
        return set_root(thread_id, node) if root.nil?

        ipoints = expecting_ipoints(thread_id, entry, rank)
        if ipoints.empty?
          if entry.is_a?(EItemProxy)
            return
          else
            raise StandardError
          end
        end

        # Check whether same node was already in use ...
        node_str = node.to_s
        shared_ip = @node_lit2ip[node_str]

        if shared_ip
          child_ip = shared_ip
          # Reminder: a node may not appear more than once on catwalk
          catwalk[thread_id] = shared_ip unless catwalk.has_value? shared_ip
        else
          curr_ip = ipoints.shift
          child_ip = curr_ip.add_child_node(node)
          @node_lit2ip[node_str] = child_ip

          if curr_ip.full?
            # rollup(curr_ip)
          end
        end

        ipoints.each { |ip| child_ip.share_with(ip) }

        child_ip
      end

      def add_or_node(thread_id, entry, rank, node)
        return set_root(thread_id, node) if root.nil?

        # TODO replace indices by ipoints
        ipoints = expecting_ipoints(thread_id, entry, rank)
        raise StandardError if ipoints.empty?

        node_str = node.to_s
        shared_ip = @node_lit2ip[node_str]
        if shared_ip
          child_ip = shared_ip
          catwalk[thread_id] = child_ip
        else
          curr_ip = ipoints.shift
          child_ip = curr_ip.add_child_node(node)
          @node_lit2ip[node_str] = child_ip
          catwalk[child_ip.thread] = child_ip
        end

        ipoints.each do |curr_ip|
          child_ip.share_with(curr_ip)
        end

        child_ip
      end

      def replace_by_children(parent_ip, children_ip)
        catwalk.delete(parent_ip.thread)
        children_ip.each do |ch|
          next if ch.full?

          catwalk[ch.thread] = ch
        end
      end

      def map(node, ipoint)
        @node_lit2ip[node.to_s] = ipoint
      end

      private

      def set_root(thread_id, node)
        @root = build_ipoint(thread_id, nil, node)
        @catwalk[thread_id] = root
        puts "  Root: #{node}"

        root
      end

      # @return [Array<InsertionPoint>]
      def expecting_ipoints(thread_id, entry, rank)
        ipoints = []
        candidates = catwalk[thread_id]
        return [] if candidates.nil?

        if candidates.is_a? Array
          candidates.each { |ip| ipoints << ip if ip.expect?(entry, rank) }
        else
          ipoints << candidates if candidates.expect?(entry, rank)
        end

        ipoints
      end

      def matching_ipoints(thread_id, entry, rank)
        ipoints = []
        candidates = catwalk[thread_id]
        return [] if candidates.nil?

        if candidates.is_a? Array
          candidates.each do |ip|
            ipoints << ip if ip.origin == entry.origin && ip.dotted_item == entry.dotted_item
          end
        else
          ip = candidates
          if ip.origin == entry.origin && ip.dotted_item == entry.dotted_item
            ipoints << ip
          end
        end

        ipoints
      end

      def match_indices(entry, prev_entry, rank)
        indices = []

        catwalk.each_with_index do |ipoint, index|
          if ipoint.origin == prev_entry.origin && ipoint.dotted_item == prev_entry.dotted_item
            indices << index
          end
        end
        indices =  indices.select do |i|
          catwalk[i].expect?(entry, rank)
        end

        indices.reverse
      end
    end # class
  end # module
end # module


