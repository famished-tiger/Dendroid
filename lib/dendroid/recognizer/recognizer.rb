# frozen_string_literal: true

require_relative '../grm_analysis/grm_analyzer'
require_relative 'start_item'
require_relative 'success_item'
require_relative 'e_item'
require_relative 'chart'

module Dendroid
  # This module host classes needed to implement an Earley recognizer.
  module Recognizer
    # A recognizer determines whether the input text complies to the grammar (syntax) rules.
    # This class implements the Earley recognition algorithm.
    class Recognizer
      # @return [GrmAnalysis::GrmAnalyzer]
      attr_reader :grm_analysis

      # @return [Object]
      attr_reader :tokenizer

      # rubocop: disable Metrics/AbcSize
      # rubocop: disable Metrics/CyclomaticComplexity
      # rubocop: disable Metrics/PerceivedComplexity

      # @param grammar [Dendroid::Syntax::Grammar]
      # @param tokenizer [Object]
      def initialize(grammar, tokenizer)
        @grm_analysis = GrmAnalysis::GrmAnalyzer.new(grammar)
        @tokenizer = tokenizer
      end

      # Try to read the `source` text and verify that it is syntactically correct.
      # @param source [String] Input text to recognize
      # @return [Dendroid::Recognizer::Chart]
      def run(source)
        tokenizer.input = source
        tok = tokenizer.next_token
        if tok.nil? # Empty input ?...
          if grm_analysis.grammar.start_symbol.nullable?
            earley_parse(nil)
          else
            chart = new_chart
            chart.failure(StandardError, 'Error: Input may not be empty nor blank.')
            chart
          end
        else
          earley_parse(tok)
        end
      end

      # Run the Earley algorithm
      # @param initial_token [Dendroid::Lexical::Token|NilClass]
      def earley_parse(initial_token)
        chart = new_chart
        tokens = initial_token.nil? ? [] : [initial_token]
        eos_reached = initial_token.nil?
        predicted_symbols = [Set.new]
        rank = 0

        loop do
          eos_reached ||= advance_next_token(tokens, predicted_symbols)

          advance = false
          curr_rank = rank
          curr_set = chart[curr_rank]
          curr_set.each do |entry|
            # For each entry, do either completer, scanner or predictor action
            tick = do_entry_action(chart, entry, curr_rank, tokens, :genuine, predicted_symbols)
            advance ||= tick
          end

          rank += 1 if advance
          break if eos_reached && !advance
          break unless advance
        end

        chart.tokens = tokens
        augment_chart(chart)
        determine_outcome(chart)
        chart
      end

      private

      def new_chart
        top_symbol = grm_analysis.grammar.start_symbol

        prd = grm_analysis.grammar.nonterm2production[top_symbol]
        chart = Chart.new
        seed_items = prd.predicted_items
        seed_items.each do |item|
          entry = EItem.new(item, 0)
          entry.algo = :predictor
          chart.seed_last_set(entry)
        end

        chart
      end

      def augment_chart(aChart)
        top_symbol = aChart.start_symbol
        start_item = StartItem.new(top_symbol)
        first_item_set = aChart.item_sets[0]
        first_item_set.items.each do |entry|
          if entry.lhs == top_symbol && entry.algo == :predictor
            entry.predecessors << start_item
          end
        end
        first_item_set.items.unshift(start_item)
      end

      def advance_next_token(tokens, predicted_symbols)
        eos_reached = false
        tok = tokenizer.next_token
        if tok
          tokens << tok
        else
          eos_reached = true
        end

        predicted_symbols << Set.new unless eos_reached
        eos_reached
      end

      def do_entry_action(chart, entry, rank, tokens, mode, predicted_symbols)
        advance = false

        if entry.completed?
          completer(chart, entry, rank, tokens, mode)
        elsif entry.next_symbol.terminal?
          advance = scanner(chart, entry, rank, tokens)
        else
          predictor(chart, entry, rank, tokens, mode, predicted_symbols)
        end

        advance
      end

      # procedure PREDICTOR((A → α•Bβ, j), k)
      #     for each (B → γ) in GRAMMAR_RULES_FOR(B) do
      #         ADD_TO_SET((B → •γ, k), S[k])
      #     end
      #   Assuming next symbol is a non-terminal
      #
      #   Error case: next actual token matches none of the expected tokens.
      def predictor(chart, item, rank, tokens, mode, _predicted_symbols)
        next_symbol = item.next_symbol
        # if mode == :genuine
        #   predicted_symbols << Set.new if rank == predicted_symbols.size
        #   predicted = predicted_symbols[rank]
        #   return if predicted.include?(next_symbol)
        #
        #   predicted.add(next_symbol)
        # end

        curr_set = chart[rank]
        next_token = tokens[rank]
        prd = grm_analysis.symbol2production(next_symbol)
        entry_items = prd.predicted_items
        added = []
        entry_items.each do |entry|
          member = entry.next_symbol
          if member&.terminal?
            next unless next_token
            next if (member.name != next_token.terminal) && mode == :genuine
          end
          added << add_item(curr_set, entry, rank, item, :predictor)
        end
        # Use trick from paper John Aycock and R. Nigel Horspool: "Practical Earley Parsing"
        return unless next_symbol.nullable?

        next_item = grm_analysis.next_item(item.dotted_item)
        return unless next_item
        empty_item = entry_items.find(&:empty?)
        empty_entry = add_item(curr_set, empty_item, rank, item, :predictor)

        add_item(curr_set, next_item, item.origin, empty_entry, :completer)
      end

      # procedure SCANNER((A → α•aβ, j), k, words)
      #     if j < LENGTH(words) and a ⊂ PARTS_OF_SPEECH(words[k]) then
      #         ADD_TO_SET((A → αa•β, j), S[k+1])
      #     end
      # Assuming next symbol is a terminal
      def scanner(chart, scan_item, rank, tokens)
        advance = false
        dit = scan_item.dotted_item
        if rank < tokens.size && dit.next_symbol.name == tokens[rank].terminal
          new_rank = rank + 1
          chart.append_new_set if chart[new_rank].nil?
          next_dotted_item = grm_analysis.next_item(dit)
          add_item(chart[new_rank], next_dotted_item, scan_item.origin, scan_item, :scanner)
          advance = true
        end

        advance
      end

      # procedure COMPLETER((B → γ•, x), k)
      #     for each (A → α•Bβ, j) in S[x] do
      #         ADD_TO_SET((A → αB•β, j), S[k])
      #     end
      def completer(chart, item, rank, tokens, mode)
        return if item.dotted_item.empty?

        origin = item.origin

        curr_set = chart[rank]
        set_at_origin = chart[origin]
        next_token = tokens[rank]
        callers = set_at_origin.items_expecting(item.lhs)
        callers.each do |call_item|
          return_item = grm_analysis.next_item(call_item.dotted_item)
          next unless return_item

          member = return_item.next_symbol
          if member&.terminal? && (mode == :genuine)
            next unless next_token
            next if member.name != next_token.terminal
          end

          add_item(curr_set, return_item, call_item.origin, item, :completer)
        end
      end

      def seed_set(chart, rank)
        curr_set = chart[rank]
        previous_set = chart[rank - 1]
        curr_set.clear
        scan_entries = previous_set.select { |ent| ent.dotted_item.next_symbol&.terminal? }
        scan_entries.map do |ent|
          new_item = grm_analysis.next_item(ent.dotted_item)
          curr_set.add_item(EItem.new(new_item, ent.origin))
        end
      end

      def add_item(item_set, dotted_item, origin, predecessor, procedure)
        new_item = EItem.new(dotted_item, origin)
        added = item_set.add_item(new_item)
        if predecessor # && !(predecessor == added)
          added.add_predecessor(predecessor)
          added.predecessors.uniq! unless added.equal?(new_item)
        end
        added.algo = procedure

        added
      end

      def determine_outcome(chart)
        tokens = chart.tokens
        if chart.size == tokens.size + 1
          top_symbol = grm_analysis.grammar.start_symbol
          top_rule = grm_analysis.grammar.nonterm2production[top_symbol]
          final_items = top_rule.reduce_items
          last_set = chart.item_sets.last
          successes = []
          last_set.each do |entry|
            next if !entry.origin.zero? || entry.is_a?(StartItem)|| !final_items.include?(entry.dotted_item)

            successes << entry
          end

          unless successes.empty?
            success = true
            success_item = SuccessItem.new(top_symbol)
            success_item.predecessors.concat(successes)
            last_set.items << success_item
            chart.success_entry = success_item
          end
        end

        unless chart.success?
          # Error detected...
          replay_last_set(chart, tokens)
          if chart.size < tokens.size + 1
            # Recognizer stopped prematurely...
            offending_token = tokens[chart.size - 1]
            pos = offending_token.position
            (line, col) = [pos.lineno, pos.column]
            terminals = expected_terminals(chart)
            prefix = "Syntax error at or near token line #{line}, column #{col} >>>#{offending_token.source}<<<"
            expectation = terminals.size == 1 ? terminals[0].name.to_s : "one of: [#{terminals.map(&:name).join(', ')}]"
            err_msg = "#{prefix} Expected #{expectation}, found a #{offending_token.terminal} instead."
            chart.failure(StandardError, err_msg)
          elsif chart.size == tokens.size + 1
            # EOS unexpected...
            last_token = tokens.last
            pos = last_token.position
            (line, col) = [pos.lineno, pos.column]
            terminals = expected_terminals(chart)
            prefix = "Line #{line}, column #{col}: Premature end of input after '#{last_token.source}'"
            expectation = terminals.size == 1 ? terminals[0].name.to_s : "one of: [#{terminals.map(&:name).join(', ')}]"
            err_msg = "#{prefix}, expected: #{expectation}."
            chart.failure(StandardError, err_msg)
          end
        end
        chart.success?
      end

      def expected_terminals(chart)
        last_set = chart.last
        terminals = last_set.items.each_with_object([]) do |ent, result|
          result << ent.next_symbol if ent.pre_scan?
          result
        end
        terminals.uniq!

        terminals
      end

      def replay_last_set(chart, tokens)
        rank = chart.size - 1
        seed_set(chart, rank) # Re-initialize last set with scan entries

        # Replay in full the actions for last set
        chart[rank].each do |entry|
          do_entry_action(chart, entry, rank, tokens, :error, [Set.new])
        end
      end
    end # class

    # rubocop: enable Metrics/AbcSize
    # rubocop: enable Metrics/CyclomaticComplexity
    # rubocop: enable Metrics/PerceivedComplexity
  end # module
end # module
