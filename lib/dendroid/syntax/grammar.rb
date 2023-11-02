# frozen_string_literal: true

require 'set'

module Dendroid
  module Syntax
    # A grammar specifies the syntax of a language.
    #   Formally, a grammar has:
    #   * One start symbol,
    #   * One or more other production rules,
    #   * Each production has a rhs that is a sequence of grammar symbols.
    #   * Grammar symbols are categorized into:
    #     -terminal symbols
    #     -non-terminal symbols
    class Grammar
      # The list of grammar symbols in the language.
      # @return [Array<Dendroid::Syntax::GrmSymbol>] The terminal and non-terminal symbols.
      attr_reader :symbols

      # The list of production rules for the language.
      # @return [Array<Dendroid::Syntax::Rule>] Array of rules for the grammar.
      attr_reader :rules

      # A Hash that maps symbol names to their grammar symbols
      # @return [Hash{String => Dendroid::Syntax::GrmSymbol}]
      attr_reader :name2symbol

      # TODO: make nonterminal - rules one-to-one
      # A Hash that maps symbol names to their grammar symbols
      # @return [Hash{Dendroid::Syntax::GrmSymbol => Dendroid::Syntax::Rule}]
      attr_reader :nonterm2productions

      # Constructor.
      # @param terminals [Array<Dendroid::Syntax::Terminal>]
      def initialize(terminals)
        @symbols = []
        @name2symbol = {}
        add_terminals(terminals)
      end

      # Add a rule to the grammar
      # @param rule [Dendroid::Syntax::Rule]
      def add_rule(rule)
        if @rules.nil?
          @rules = []
          @nonterm2productions = {}
        end
        # TODO: add test for duplicate productions
        if nonterm2productions[rule.head]&.include? rule
          raise StandardError, "Production rule '#{rule}' appears more than once in the grammar."
        end

        add_symbol(rule.head)
        rule.nonterminals.each { |nonterm| add_symbol(nonterm) }
        rules << rule
        nonterm2productions[rule.head] = [] unless nonterm2productions.include? rule.head
        nonterm2productions[rule.head] << rule
      end

      # Return the start symbol for the language
      # @return [Dendroid::Syntax::NonTerminal]
      def start_symbol
        rules.first.lhs
      end

      # A event method to notify the grammar that all grammar rules
      # have been entered. The grammar, in turn, reacts by validating the
      # production rules.
      def complete!
        validate
        analyze
      end

      private

      # rubocop: disable Metrics/AbcSize
      # rubocop: disable Metrics/BlockNesting
      # rubocop: disable Metrics/MethodLength
      # rubocop: disable Metrics/PerceivedComplexity
      def add_terminals(terminals)
        terminals.each { |term| add_symbol(term) }
      end

      def add_symbol(symb)
        return if name2symbol.include? symb.name

        symbols.push(symb)
        name2symbol[symb.name] = symb
        name2symbol[symb.name.to_s] = symb
      end

      def validate
        at_least_one_terminal
        are_terminals_referenced?
        are_nonterminals_rewritten?
        are_symbols_productive?
        are_symbols_reachable?
      end

      def analyze
        mark_nullable_symbols
      end

      # Does the grammar contain at least one terminal symbol?
      def at_least_one_terminal
        found = symbols.any?(&:terminal?)

        return true if found

        err_msg = "Grammar doesn't contain any terminal symbol."
        raise StandardError, err_msg
      end

      # Does every terminal symbol appear at least once
      # in a rhs of a production rule?
      def are_terminals_referenced?
        all_terminals = Set.new(symbols.select(&:terminal?))
        terms_in_rhs = rules.reduce(Set.new) do |collected, prd|
          found = prd.terminals
          collected.merge(found)
        end
        check_ok = all_terminals == terms_in_rhs
        unless check_ok
          unused_terms = all_terminals.difference(terms_in_rhs)
          text = unused_terms.map(&:name).join("', '")
          err_msg = "Terminal symbols '#{text}' never appear in production rules."
          raise StandardError, err_msg
        end

        check_ok
      end

      def are_nonterminals_rewritten?
        all_nonterminals = Set.new(symbols.reject(&:terminal?))

        symbs_in_lhs = rules.reduce(Set.new) do |collected, prd|
          collected.add(prd.head)
        end
        check_ok = all_nonterminals == symbs_in_lhs
        unless check_ok
          undefined_nterms = all_nonterminals.difference(symbs_in_lhs)
          text = undefined_nterms.map(&:name).join("', '")
          err_msg = "Non-terminal symbols '#{text}' never appear in head of any production rule."
          raise StandardError, err_msg
        end

        check_ok
      end

      def are_symbols_reachable?
        unreachable = unreachable_symbols
        return true if unreachable.empty?

        text = unreachable.to_a.map(&:name).join("', '")
        err_msg = "Symbols '#{text}' are unreachable from start symbol."
        raise StandardError, err_msg
      end

      def are_symbols_productive?
        non_productive = mark_non_productive_symbols
        return true if non_productive.empty?

        text = non_productive.to_a.map(&:name).join("', '")
        err_msg = "Symbols '#{text}' are non-productive."
        raise StandardError, err_msg
      end

      # Are all symbols reachable from start symbol?
      def unreachable_symbols
        backlog = [start_symbol]
        set_reachable = Set.new(backlog.dup)

        begin
          reachable_sym = backlog.pop
          prods = nonterm2productions[reachable_sym]
          prods.each do |prd|
            prd.rhs_symbols.each do |member|
              unless member.terminal? || set_reachable.include?(member)
                backlog.push(member)
              end
              set_reachable.add(member)
            end
          end
        end until backlog.empty?

        all_symbols = Set.new(symbols)
        all_symbols - set_reachable
      end

      def mark_non_productive_symbols
        prod_count = rules.size
        backlog = Set.new(0...prod_count)
        rules.each_with_index do |prd, i|
          backlog.delete(i) if prd.productive?
        end
        until backlog.empty?
          to_remove = []
          backlog.each do |i|
            prd = rules[i]
            to_remove << i if prd.productive?
          end
          break if to_remove.empty?

          backlog.subtract(to_remove)
        end

        backlog.each { |i| rules[i].non_productive }
        non_productive = symbols.reject(&:productive?)
        non_productive.each { |symb| symb.productive = false }
        non_productive
      end

      def mark_nullable_symbols
        nullable_found = false
        sym2seqs = {}

        nonterm2productions.each_pair do |sym, prods|
          if prods.any?(&:empty?)
            sym.nullable = nullable_found = true
          else
            sym2seqs[sym] = prods.map(&:rhs).flatten
          end
        end

        if nullable_found
          backlog = {} # { SymbolSequence => [Integer, Symbol] }
          sym2seqs.each do |sym, seqs|
            seqs.each { |sq| backlog[sq] = [0, sym] }
          end

          begin
            seqs_done = []
            backlog.each_pair do |sq, (elem_index, lhs)|
              member = sq[elem_index]
              if member.terminal?
                seqs_done << sq # stop with this sequence: it is non-nullable
                backlog[sq] = [-1, lhs]
              elsif member.nullable?
                if elem_index == sq.size - 1
                  seqs_done << sq # end of sequence reached...
                  backlog[sq] = [-1, lhs]
                  lhs.nullable = true
                else
                  backlog[sq] = [elem_index + 1, lhs]
                end
              end
            end
            seqs_done.each do |sq|
              next unless backlog.include? sq

              (_, lhs) = backlog[sq]
              if lhs.nullable?
                to_drop = sym2seqs[lhs]
                to_drop.each { |seq| backlog.delete(seq) }
              else
                backlog.delete(sq)
              end
            end
          end until backlog.empty? || seqs_done.empty?
        end

        symbols.each do |sym|
          next if sym.terminal?

          sym.nullable = false if sym.nullable.nil?
        end
      end
      # rubocop: enable Metrics/AbcSize
      # rubocop: enable Metrics/BlockNesting
      # rubocop: enable Metrics/MethodLength
      # rubocop: enable Metrics/PerceivedComplexity
    end # class
  end # module
end # module
