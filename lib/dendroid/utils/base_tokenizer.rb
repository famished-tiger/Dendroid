# frozen_string_literal: true

require 'strscan'
require_relative '../lexical/token_position'
require_relative '../lexical/literal'

module Dendroid
  # This module contains helper classes (e.g. a tokenizer generator)
  module Utils
    # A basic tokenizer.
    # Responsibility: break input into a sequence of token objects.
    # This class defines a simple DSL to build a tokenizer.
    class BaseTokenizer
      # @return [StringScanner] Low-level input scanner
      attr_reader :scanner

      # @return [Integer] The current line number
      attr_reader :lineno

      # @return [Integer] Position of last start of line in the input string
      attr_reader :line_start

      # @return [Hash{Symbol, Array<Regexp>}]
      attr_reader :actions

      # Constructor
      # @param aBlock [Proc]
      def initialize(&aBlock)
        @scanner = StringScanner.new('')
        @actions = { skip: [], scan_verbatim: [], scan_value: [] }
        defaults
        return unless block_given?

        instance_exec(&aBlock)
      end

      # Reset the tokenizer and set new text to tokenize
      # @param source [String]
      def input=(source)
        reset
        scanner.string = source
      end

      # Reset the tokenizer
      def reset
        @lineno = 1
        @line_start = 0
        scanner.reset
      end

      # action, pattern, terminal?, conversion?
      # action = skip, skip_nl, scan

      # Associate the provided pattern to the action of skipping a newline and
      # incrementing the line counter.
      # @param pattern [Regexp]
      def skip_nl(pattern)
        actions[:skip_nl] = pattern
      end

      # Associate the provided pattern with the action to skip whitespace(s).
      # @param pattern [Regexp]
      def skip_ws(pattern)
        actions[:skip_ws] = pattern
      end

      # Associate the provided pattern with the action to skip the matching text.
      # @param pattern [Regexp]
      def skip(pattern)
        if actions[:skip].empty?
          actions[:skip] = pattern
        else
          new_pattern = actions[:skip].union(pattern)
          actions[:skip] = new_pattern
        end
      end

      # Associate the provided pattern with the action to tokenize the matching text
      # @param pattern [Regexp]
      def scan_verbatim(pattern)
        patt = normalize_pattern(pattern)
        if actions[:scan_verbatim].empty?
          actions[:scan_verbatim] = patt
        else
          new_pattern = actions[:scan_verbatim].union(patt)
          actions[:scan_verbatim] = new_pattern
        end
      end

      # Associate the provided pattern with the action to tokenize the matching text
      # as an instance of the given terminal symbol and convert the matching text into
      # a value by using the given conversion.
      # @param pattern [Regexp]
      # @param terminal [Dendroid::Syntax::Terminal]
      # @param conversion [Proc] a Proc (lambda) that takes a String as argument and return a value.
      def scan_value(pattern, terminal, conversion)
        patt = normalize_pattern(pattern)
        tuple = [patt, terminal, conversion]
        if actions[:scan_value].empty?
          actions[:scan_value] = [tuple]
        else
          actions[:scan_verbatim] << tuple
        end
      end

      # Set the mapping between a verbatim text to its corresponding terminal symbol name
      # @param mapping [Hash{String, String}]
      def map_verbatim2terminal(mapping)
        @verbatim2terminal = mapping
      end

      # rubocop: disable Metrics/AbcSize

      # Return the next token (if any) from the input stream.
      # @return [Dendroid::Lexical::Token, NilClass]
      def next_token
        token = nil

        # Loop until end of input reached or token found
        until scanner.eos?
          if scanner.skip(actions[:skip_nl])
            next_line_scanned
            next
          end

          next if scanner.skip(actions[:skip_ws]) # Skip whitespaces

          if (text = scanner.scan(actions[:scan_verbatim]))
            token = verbatim_scanned(text)
            break
          end

          tuple = actions[:scan_value].find do |(pattern, _terminal, _conversion)|
            scanner.check(pattern)
          end
          if tuple
            (pattern, terminal, conversion) = tuple
            text = scanner.scan(pattern)
            token = value_scanned(text, terminal, conversion)
            break
          end

          # Unknown token
          col = scanner.pos - line_start + 1
          erroneous = scanner.peek(1).nil? ? '' : scanner.scan(/./)
          raise StandardError, "Error: [line #{lineno}:#{col}]: Unexpected character #{erroneous}."
        end

        token
      end

      # rubocop: enable Metrics/AbcSize

      protected

      def defaults
        # Defaults
        skip_nl(/(?:\r\n)|\r|\n/) # Skip newlines
        skip_ws(/[ \t\f]+/) # Skip blanks
      end

      private

      def normalize_pattern(pattern)
        case pattern
        when String
          Regexp.new(Regexp.escape(pattern))
        when Array
          regexes = pattern.map { |patt| normalize_pattern(patt) }
          Regexp.union(regexes)
        else
          pattern
        end
      end

      def next_line_scanned
        @lineno += 1
        @line_start = scanner.pos
      end

      def verbatim_scanned(text)
        symbol_name = @verbatim2terminal[text]
        begin
          lex_length = text ? text.size : 0
          col = scanner.pos - lex_length - @line_start + 1
          pos = Lexical::TokenPosition.new(@lineno, col)
          token = Lexical::Token.new(text, pos, symbol_name)
        rescue StandardError => e
          puts "Failing with '#{symbol_name}' and '#{text}'"
          raise e
        end

        token
      end

      def value_scanned(aText, aSymbolName, conversion)
        value = conversion.call(aText)
        lex_length = aText ? aText.size : 0
        col = scanner.pos - lex_length - @line_start + 1
        build_literal(aSymbolName, value, aText, col)
      end

      def build_literal(aSymbolName, aValue, aText, aPosition)
        pos = if aPosition.is_a?(Integer)
                col = aPosition
                Lexical::TokenPosition.new(@lineno, col)
              else
                aPosition
              end

        Lexical::Literal.new(aText.dup, pos, aSymbolName, aValue)
      end
    end # class
  end # module
end # module
