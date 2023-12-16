# frozen_string_literal: true

require_relative '..\syntax\terminal'
require_relative '..\syntax\non_terminal'
require_relative '..\syntax\symbol_seq'
require_relative '..\syntax\rule'
require_relative '..\syntax\grammar'

module Dendroid
  # This module contains classes that define Domain-Specific Language specialized
  # in grammar definition.
  module GrmDSL
    # Builder GoF pattern: Builder builds a complex object.
    #   here the builder creates a grammar from simpler objects
    #   (symbols and production rules)
    #   and using a step by step approach.
    class BaseGrmBuilder
      # @return [Symbol] one of: :declaring, :building, :complete
      attr_reader :state

      # @return [Hash{String, Dendroid::Syntax::GrmSymbol}] The mapping of grammar symbol names
      #   to the matching grammar symbol object.
      attr_reader :symbols

      # @return [Array<Dendroid::Syntax::Rule>] The list of rules of the grammar
      attr_reader :rules

      # Creates a new grammar builder object.
      # @param aBlock [Proc] code block used to build the grammar.
      # @example Building a tiny English grammar
      #   builder = Rley::Syntax::GrammarBuilder.new do
      #     declare_terminals('n', 'v', 'adj', 'det')
      #     rule 'S' => 'NP VP'
      #     rule 'VP' => 'v NP'
      #     rule 'NP' => ['det n', 'adj NP']
      #   end
      #   # Now with `builder`, let's create the grammar
      #   tiny_eng = builder.grammar
      def initialize(&aBlock)
        @symbols = {}
        @rules = []
        @state = :declaring

        return unless block_given?

        instance_exec(&aBlock)
        grammar_complete!
      end

      # Add the given terminal symbols to the grammar of the language
      # @param terminalSymbols [String, Terminal] 1..* terminal symbols.
      # @return [void]
      def declare_terminals(*terminalSymbols)
        err_msg = "Terminal symbols may only be declared in state :declaring, current state is: #{state}"
        raise StandardError, err_msg unless state == :declaring

        new_symbs = build_symbols(Dendroid::Syntax::Terminal, terminalSymbols)
        symbols.merge!(new_symbs)
      end

      # Add a production rule in the grammar given one
      # key-value pair of the form: String => String.
      #   Where the key is the name of the non-terminal appearing in the
      #   left side of the rule.
      #   When the value is a String, it is a sequence of grammar symbol names separated by space.
      #   When the value is an array of String, the elements represent an alternative rhs
      # The rule is created and inserted in the grammar.
      # @example
      #   builder.rule('sentence' => 'noun_phrase verb_phrase')
      #   builder.rule('noun_phrase' => ['noun', 'adj noun'])
      # @param productionRuleRepr [Hash{String, String|Array<String>}]
      #   A Hash-based representation of a production.
      # @return [Dendroid::Syntax::Rule] The created Production or Choice instance
      def rule(productionRuleRepr)
        raise StandardError, 'Cannot add a production rule in state :complete' if state == :complete

        @state = :building

        return nil unless productionRuleRepr.is_a?(Hash)

        head_name = productionRuleRepr.keys.first
        if symbols.include? head_name
          err_msg = "Terminal symbol '#{head_name}' may not be on left-side of a rule."
          raise StandardError, err_msg if symbols[head_name].is_a?(Dendroid::Syntax::Terminal)
        else
          symbols.merge!(build_symbols(Dendroid::Syntax::NonTerminal, [head_name]))
        end
        lhs = symbols[head_name]
        raw_rhs = productionRuleRepr.values.first

        if raw_rhs.is_a? String
          new_prod = Dendroid::Syntax::Rule.new(lhs, [build_symbol_seq(raw_rhs)])
        else
          rhs = raw_rhs.map { |raw| build_symbol_seq(raw) }
          new_prod = Dendroid::Syntax::Rule.new(lhs, rhs)
        end
        rules << new_prod
        new_prod
      end

      # A method used to notify the builder that the grammar is complete
      #   (i.e. all rules were entered).
      def grammar_complete!
        @state = :complete
      end

      # Generate the grammar according to the specifications.
      # @return [Dendroid::Syntax::Grammar]
      def grammar
        terminals = symbols.values.select(&:terminal?)
        grm = Dendroid::Syntax::Grammar.new(terminals)
        rules.each { |prod| grm.add_rule(prod) }
        grm.complete!
        grm
      end

      private

      def build_symbol_seq(raw_symbols)
        symb_array = []
        raw_stripped = raw_symbols.strip
        return Dendroid::Syntax::SymbolSeq.new([]) if raw_stripped.empty?

        symbol_names = raw_stripped.split(/(?: |\t)+/)
        symbol_names.each do |symb_name|
          unless symbols.include?(symb_name)
            symbols.merge!(build_symbols(Dendroid::Syntax::NonTerminal, [symb_name]))
          end
          symb_array << symbols[symb_name]
        end

        Dendroid::Syntax::SymbolSeq.new(symb_array)
      end

      # Add the given grammar symbols.
      # @param aClass [Class] The class of grammar symbols to instantiate.
      # @param theSymbols [Array] array of elements are treated as follows:
      #   if the element is already a grammar symbol, then it added as is,
      #   otherwise it is considered as the name of a grammar symbol
      # of the specified class to build.
      def build_symbols(aClass, theSymbols)
        symbs = {}
        theSymbols.each do |s|
          new_symbol = build_symbol(aClass, s)
          symbs[new_symbol.name] = new_symbol
          symbs[s] = new_symbol
        end

        symbs
      end

      # If the argument is already a grammar symbol object then it is
      # returned as is. Otherwise, the argument is treated as a name
      # for a new instance of the given class.
      # @param aClass [Class] The class of grammar symbols to instantiate
      # @param aSymbolArg [GrmSymbol-like or String]
      # @return [Array] list of grammar symbols
      def build_symbol(aClass, aSymbolArg)
        if aSymbolArg.is_a?(Dendroid::Syntax::GrmSymbol)
          aSymbolArg
        else
          aClass.new(aSymbolArg)
        end
      end
    end # class
  end # module
end # module
