# frozen_string_literal: true

require_relative '../grm_analysis/production_items'
require_relative '../grm_analysis/choice_items'

module Dendroid
  module GrmAnalysis
    # An analyzer performs an analysis of the grammar rules and
    # build objects (dotted items, first and follow sets) to be used
    # by a recognizer or a parser.
    class GrmAnalyzer
      # @return [Dendroid::Syntax::Grammar] The grammar subjected to analysis
      attr_reader :grammar
      attr_reader :items
      attr_reader :production2items
      attr_reader :symbol2productions

      # @return [Dendroid::Syntax::Terminal] The pseudo-terminal `__epsilon` (for empty string)
      attr_reader :epsilon

      # @return [Dendroid::Syntax::Terminal] The pseudo-terminal `$$` for end of input stream
      attr_reader :endmarker

      # @return [Hash{Syntax::NonTerminal, Array<Syntax::Terminal>}] non-terminal to FIRST SETS mapping
      attr_reader :first_sets

      # @return [Hash{Syntax::NonTerminal, Array<Syntax::Terminal>}] non-terminal to PREDICT SETS mapping
      attr_reader :predict_sets

      # @return [Hash{Syntax::NonTerminal, Array<Syntax::Terminal>}] non-terminal to FOLLOW SETS mapping
      attr_reader :follow_sets

      # Constructor.
      # Build dotted items, first, follow sets for the given grammar
      # @param aGrammar [Dendroid::Syntax::Grammar]
      def initialize(aGrammar)
        @grammar = aGrammar
        @items = []
        @production2items = {}
        @symbol2productions = {}
        @epsilon = Syntax::Terminal.new(:__epsilon)
        @endmarker = Syntax::Terminal.new(:"$$")
        @first_sets = {}
        @predict_sets = {}
        @follow_sets = {}

        build_dotted_items
        build_first_sets
        build_follow_sets
      end

      # The next item of a given dotted item
      # @param aDottedItem [DottedItem]
      def next_item(aDottedItem)
        prod = aDottedItem.rule
        prod.next_item(aDottedItem)
      end

      private

      def build_dotted_items
        grammar.rules.each do |prod|
          lhs = prod.head
          symbol2productions[lhs] = [] unless symbol2productions.include? lhs
          symbol2productions[lhs] << prod
          # production2items[prod] = []
          mixin = prod.choice? ? ChoiceItems : ProductionItems
          prod.extend(mixin)
          prod.build_items
          rule_items = prod.items.flatten
          items.concat(rule_items)
          production2items[prod] = rule_items
        end
      end

      def build_first_sets
        initialize_first_sets

        begin
          changed = false
          grammar.rules.each do |prod|
            head = prod.head
            first_head = first_sets[head]
            pre_first_size = first_head.size
            if prod.choice?
              prod.alternatives.each do |alt|
                first_head.merge(sequence_first(alt.members))
              end
            else
              first_head.merge(sequence_first(prod.body.members))
            end
            changed = true if first_head.size > pre_first_size
          end
        end until !changed
      end

      def initialize_first_sets
        grammar.symbols.each do |symb|
          if symb.terminal?
            first_sets[symb] = Set.new([symb])
          elsif symb.nullable?
            first_sets[symb] = Set.new([epsilon])
          else
            first_sets[symb] = Set.new
          end
        end
      end

      def sequence_first(symbol_seq)
        result = Set.new
        symbol_seq.each do |symb|
          result.delete(epsilon)
          result.merge(first_sets[symb])
          break unless symb.nullable?
        end

        result
      end

      # FOLLOW(A): is the set of terminals (+ end marker) that may come after the
      # non-terminal A.
      def build_follow_sets
        initialize_follow_sets

        begin
          changed = false
          grammar.rules.each do |prod|
            if prod.choice?
              prod.alternatives.each do |alt|
                body = alt.members
                next if body.empty?

                head = prod.head
                head_follow = follow_sets[head]
                # trailer = Set.new
                last = true
                last_index = body.size - 1
                last_index.downto(0) do |i|
                  symbol = body[i]
                  next if symbol.terminal?

                  follow_symbol = follow_sets[symbol]
                  size_before = follow_symbol.size
                  if last
                    # Rule: if last non-terminal member (symbol) is nullable
                    # then add FOLLOW(head) to FOLLOW(symbol)
                    follow_sets[symbol].merge(head_follow) if symbol.nullable?
                    last = false
                  else
                    symbol_seq = body.slice(i + 1, last_index - i)
                    trailer_first = sequence_first(symbol_seq)
                    contains_epsilon = trailer_first.include? epsilon
                    trailer_first.delete(epsilon) if contains_epsilon
                    follow_sets[symbol].merge(trailer_first)
                    follow_sets[symbol].merge(head_follow) if contains_epsilon
                  end
                  changed = true if follow_sets[symbol].size > size_before
                end
              end
            else
              body = prod.body.members
              next if body.empty?

              head = prod.head
              head_follow = follow_sets[head]
              # trailer = Set.new
              last = true
              last_index = body.size - 1
              last_index.downto(0) do |i|
                symbol = body[i]
                next if symbol.terminal?

                follow_symbol = follow_sets[symbol]
                size_before = follow_symbol.size
                if last
                  # Rule: if last non-terminal member (symbol) is nullable
                  # then add FOLLOW(head) to FOLLOW(symbol)
                  follow_sets[symbol].merge(head_follow) if symbol.nullable?
                  last = false
                else
                  symbol_seq = body.slice(i + 1, last_index - i)
                  trailer_first = sequence_first(symbol_seq)
                  contains_epsilon = trailer_first.include? epsilon
                  trailer_first.delete(epsilon) if contains_epsilon
                  follow_sets[symbol].merge(trailer_first)
                  follow_sets[symbol].merge(head_follow) if contains_epsilon
                end
                changed = true if follow_sets[symbol].size > size_before
              end
            end
          end
        end until !changed
      end

      def initialize_follow_sets
        grammar.symbols.each do |symb|
          next if symb.terminal?

          follow_sets[symb] = Set.new
        end

        # Initialize FOLLOW(start symbol) with end marker
        follow_sets[grammar.start_symbol].add(endmarker)
      end
    end # class
  end # module
end # module
