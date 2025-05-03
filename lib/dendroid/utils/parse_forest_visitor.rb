# frozen_string_literal: true

require_relative '../parsing/parse_result_builder'

module Dendroid
  module Parsing
    class ForestVisitorContext
      # triplet [pred, dist, color]
      # @return [Hash{Dendroid::Parsing::ParseNode => [Integer, Integer, Symbol]}]
      attr_reader :node2data

      def initialize
        @node2data = Hash.new { |h, cht_entry| h[cht_entry] = [nil, nil, :White] }
      end
    end # class

    class ParseForestVisitor
      attr_reader :root
      attr_reader :subscriber

      def initialize(root_node)
        @root = root_node
      end

      def bfs_visit(aSubscriber)
        @subscriber = aSubscriber
        @queue = []

        ctx = init_context
        aSubscriber.start(ctx)
        iter = 0

        until @queue.empty? do
          visitee = @queue[0]
          visitee_data = ctx.node2data[visitee]
          prev_visitee = visitee_data[0]
          successors = aSubscriber.before_touring(prev_visitee, visitee, ctx)

          successors.each_with_index do |succ, idx|
            if ctx.node2data[succ][2] == :White
              ctx.node2data[succ][0] = visitee
              ctx.node2data[succ][1] = visitee_data[1] + 1
              aSubscriber.visit(visitee, succ, idx, ctx)
              ctx.node2data[succ][2] = :Gray
              enqueue(succ)
            else
              aSubscriber.revisit(visitee, succ, idx, ctx)
            end
          end
          dequeue
          ctx.node2data[visitee][2] = :Black
          aSubscriber.after_touring(prev_visitee, visitee, ctx)

          iter += 1
          puts "\niter = #{iter}"
          if iter == 10
            puts "Jinx"
          end
          # break if iter == 10 # 18
        end
        aSubscriber.complete(ctx)
      end

      private

      def init_context
        ctx = ForestVisitorContext.new
        ctx.node2data[root] = [nil, 0, :White]
        enqueue(root)

        ctx
      end

      def enqueue(node)
        @queue << node
      end

      def dequeue
        @queue.shift
      end
    end # class

    class ParseForestDOTRenderer
      attr_reader :out

      def initialize(anIO)
        @out = anIO
      end

      def start(_ctx)
        header = <<-END_DOT
    digraph G {
      edge [arrowhead=open];  
        END_DOT
        out.puts header
      end

      def before_touring(_from_node, to_node, _ctx)
        if to_node
          out.puts "  #{node_naming(to_node)} [label=\"#{to_node}\"#{node_style(to_node)}];"
        end
        if to_node.is_a?(CompositeParseNode)
          to_node.children
        else
          []
        end
      end

      def visit(visitee, succ, idx, _ctx)
        if succ
          out.puts "  #{node_naming(visitee)} -> #{node_naming(succ)} [taillabel=\"[#{idx}]\"];"
        end
      end

      def revisit(visitee, succ, idx, ctx)
        visit(visitee, succ, idx, ctx)
      end

      def after_touring(_from_node, _to_node, _ctx)
        # Do nothing
      end

      def complete(_ctx)
        trailer = <<-END_DOT
    }
        END_DOT

        out.puts trailer
      end

      private

      def node_naming(node)
        "#{name_prefix(node)}_#{name_suffix(node)}"
      end

      def name_prefix(node)
        case node
        when AndNode
          prefix = 'and'

        when OrNode
          prefix = 'or'

        when TerminalNode
          prefix = 'term'
        else
          raise StandardError
        end

        prefix
      end

      def name_suffix(node)
        "#{node.object_id}"
      end

      def node_style(node)
        case node
        when AndNode
          ''

        when OrNode
          ', style=filled, color=cyan, shape=hexagon'

        else
          ', style=filled, color=lightgrey, shape=box'
        end
      end
    end # class
  end # module
end # module
