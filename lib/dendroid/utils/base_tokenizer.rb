# frozen_string_literal: true

require 'strscan'
require_relative '../lexical/token_position'
require_relative '../lexical/literal'

module Dendroid
  module Utils
    class BaseTokenizer
      attr_reader :scanner
      attr_reader :lineno
      attr_reader :line_start
      attr_reader :actions

      def initialize(&aBlock)
        @scanner = StringScanner.new('')
        @actions = { skip: [], scan_verbatim: [], scan_value: [] }
        defaults

        if block_given?
          instance_exec(&aBlock)
          # grammar_complete!
        end
      end

      def input=(source)
        scanner.string = source
        reset
      end

      def reset
        @lineno = 1
        @line_start = 0
      end

      # action, pattern, terminal?, conversion?
      # action = skip, skip_nl, scan
      def skip_nl(pattern)
        actions[:skip_nl] = pattern
      end

      def skip_ws(pattern)
        actions[:skip_ws] = pattern
      end

      def skip(pattern)
        if actions[:skip].empty?
          actions[:skip] = pattern
        else
          new_pattern = actions[:skip].union(pattern)
          actions[:skip] = new_pattern
        end
      end

      def scan_verbatim(pattern)
        patt = normalize_pattern(pattern)
        if actions[:scan_verbatim].empty?
          actions[:scan_verbatim] = patt
        else
          new_pattern = actions[:scan_verbatim].union(patt)
          actions[:scan_verbatim] = new_pattern
        end
      end

      def scan_value(pattern, terminal, convertion)
        patt = normalize_pattern(pattern)
        tuple = [patt, terminal, convertion]
        if actions[:scan_value].empty?
          actions[:scan_value] = [tuple]
        else
          actions[:scan_verbatim] << tuple
        end
      end

      def map_verbatim2terminal(mapping)
        @verbatim2terminal = mapping
      end

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

          tuple = actions[:scan_value].find do |(pattern, terminal, conversion)|
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
          raise Exception, "Error: [line #{lineno}:#{col}]: Unexpected character #{erroneous}."
        end

        token
      end

      protected

      def defaults
        # Defaults
        skip_nl /(?:\r\n)|\r|\n/  # Skip newlines
        skip_ws /[ \t\f]+/ # Skip blanks
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
        rescue Exception => e
          puts "Failing with '#{symbol_name}' and '#{text}'"
          raise e
        end

        token
      end

      def value_scanned(aText, aSymbolName, convertion)
        value = convertion.call(aText)
        lex_length = aText ? aText.size : 0
        col = scanner.pos - lex_length - @line_start + 1
        build_literal(aSymbolName, value, aText, col)
      end

      def build_literal(aSymbolName, aValue, aText, aPosition)
        pos = if aPosition.kind_of?(Integer)
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
