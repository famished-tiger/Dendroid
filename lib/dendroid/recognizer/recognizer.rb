# frozen_string_literal: true

require_relative '../grm_analysis/grm_analyzer'
require_relative 'e_item'
require_relative 'chart'

module Dendroid
  # This module host classes needed to implement an Earley recognizer
  module Recognizer
    # A recognizer determines whether the input text complies to the grammar (syntax) rules.
    # This class implements the Earley recognition algorithm.
    class Recognizer
      # @return [GrmAnalysis::GrmAnalyzer]
      attr_reader :grm_analysis

      # @return [Object]
      attr_reader :tokenizer

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
        if tok.nil? && !grm_analysis.grammar.start_symbol.nullable?
          chart = new_chart
          chart.failure(StandardError, 'Error: Input may not be empty nor blank.')
          chart
        else
          earley_parse(tok)
        end
      end

      # Run the Earley algorithm
      # @param initial_token [Dednroid::Lexical::Token]
      def earley_parse(initial_token)
        chart = new_chart
        tokens = [initial_token]
        predicted_symbols = [Set.new]
        eos_reached = initial_token.nil?
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

        determine_outcome(chart, tokens)
        chart
      end

      private

      def new_chart
        top_symbol = grm_analysis.grammar.start_symbol

        prd = grm_analysis.grammar.nonterm2production[top_symbol]
        chart = Chart.new
        seed_items = prd.predicted_items
        seed_items.each { |item| chart.seed_last_set(EItem.new(item, 0)) }

        chart
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
      def predictor(chart, item, rank, tokens, mode, predicted_symbols)
        next_symbol = item.next_symbol
        if mode == :genuine
          predicted_symbols << Set.new if rank == predicted_symbols.size
          predicted = predicted_symbols[rank]
          return if predicted.include?(next_symbol)

          predicted.add(next_symbol)
        end

        curr_set = chart[rank]
        next_token = tokens[rank]
        prd = grm_analysis.symbol2production(next_symbol)
        entry_items = prd.predicted_items
        entry_items.each do |entry|
          member = entry.next_symbol
          if member&.terminal?
            next unless next_token
            next if (member.name != next_token.terminal) && mode == :genuine
          end

          new_item = EItem.new(entry, rank)
          curr_set.add_item(new_item)
        end
        # Use trick from paper John Aycock and R. Nigel Horspool: "Practical Earley Parsing"
        return unless next_symbol.nullable?

        next_item = grm_analysis.next_item(item.dotted_item)
        return unless next_item

        new_item = EItem.new(next_item, item.origin)
        curr_set.add_item(new_item)
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
          new_item = EItem.new(next_dotted_item, scan_item.origin)
          chart[new_rank].add_item(new_item)
          advance = true
        end

        advance
      end

      # procedure COMPLETER((B → γ•, x), k)
      #     for each (A → α•Bβ, j) in S[x] do
      #         ADD_TO_SET((A → αB•β, j), S[k])
      #     end
      def completer(chart, item, rank, tokens, mode)
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

          new_item = EItem.new(return_item, call_item.origin)
          curr_set.add_item(new_item)
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

      def determine_outcome(chart, tokens)
        success = false
        if chart.size == tokens.size + 1
          top_symbol = grm_analysis.grammar.start_symbol
          top_rule = grm_analysis.grammar.nonterm2production[top_symbol]
          final_items = top_rule.reduce_items
          last_set = chart.item_sets.last
          last_set.each do |entry|
            next if !entry.origin.zero? || !final_items.include?(entry.dotted_item)

            success = true
          end
        end

        unless success
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
        chart.success = success
      end

      def expected_terminals(chart)
        last_set = chart.last
        terminals = last_set.items.reduce([]) do |result, ent|
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
  end # module
end # module
