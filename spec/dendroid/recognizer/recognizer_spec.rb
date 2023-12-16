# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../support/sample_grammars'
require_relative '../../../lib/dendroid/recognizer/recognizer'

describe Dendroid::Recognizer::Recognizer do
  include SampleGrammars
  let(:grammar1) { grammar_l1 }

  def comp_expected_actuals(chart, expectations)
    expectations.each_with_index do |set, rank|
      expect(chart[rank].to_s).to eq(set.join("\n"))
    end
  end

  # Implements a dotted item: expression => NUMBER . PLUS NUMBER
  subject { described_class.new(grammar1, tokenizer_l1) }

  context 'Initialization:' do
    it 'is initialized with a grammar' do
      expect { described_class.new(grammar1, tokenizer_l1) }.not_to raise_error
    end

    it 'knows its grammar analyzer' do
      expect(subject.grm_analysis).to be_kind_of(Dendroid::GrmAnalysis::GrmAnalyzer)
      expect(subject.grm_analysis.grammar).to eq(grammar1)
    end

    it 'knows its tokenizer' do
      expect(subject.grm_analysis).to be_kind_of(Dendroid::GrmAnalysis::GrmAnalyzer)
      expect(subject.grm_analysis.grammar).to eq(grammar1)
    end
  end # context

  context 'Recognizer at work:' do
    it 'can recognize example from Wikipedia' do
      chart = subject.run('2 + 3 * 4')
      expect(chart).to be_successful

      set0 = [ # . 2 + 3 * 4'
        'p => . s @ 0',
        's => . s PLUS m @ 0',
        's => . m @ 0',
        'm => . m STAR t @ 0',
        'm => . t @ 0',
        't => . INTEGER @ 0'
      ]
      set1 = [ # 2 . + 3 * 4'
        't => INTEGER . @ 0',
        'm => t . @ 0',
        's => m . @ 0',
        # 'm => m . STAR t @ 0',
        'p => s . @ 0', # Can be ruled out (next token != eos)
        's => s . PLUS m @ 0'
      ]
      set2 = [ # 2 + . 3 * 4'
        's => s PLUS . m @ 0',
        'm => . m STAR t @ 2',
        'm => . t @ 2',
        't => . INTEGER @ 2'
      ]
      set3 = [ # 2 + 3 . * 4'
        't => INTEGER . @ 2',
        'm => t . @ 2',
        's => s PLUS m . @ 0',
        'm => m . STAR t @ 2',
        'p => s . @ 0' # Can be ruled out (next token != eos)
        # 's => s . PLUS m @ 0'
      ]
      set4 = [ # 2 + 3 * . 4'
        'm => m STAR . t @ 2',
        't => . INTEGER @ 4'
      ]
      set5 = [ # 2 + 3 * 4 .'
        't => INTEGER . @ 4',
        'm => m STAR t . @ 2',
        's => s PLUS m . @ 0',
        # 'm => m . STAR t @ 2',
        'p => s . @ 0'
        # 's => s . PLUS m @ 0'
      ]
      [set0, set1, set2, set3, set4, set5].each_with_index do |set, rank|
        expect(chart[rank].to_s).to eq(set.join("\n"))
      end
    end

    it 'can recognize example for L2 language' do
      recognizer = described_class.new(grammar_l2, tokenizer_l2)
      chart = recognizer.run('1 + (2 * 3 - 4)')
      expect(chart).to be_successful

      set0 = [ # . 1 + (2 * 3 - 4)
        'p => . sum @ 0',
        'sum => . sum PLUS product @ 0',
        'sum => . sum MINUS product @ 0',
        'sum => . product @ 0',
        'product => . product STAR factor @ 0',
        'product => . product SLASH factor @ 0',
        'product => . factor @ 0',
        # 'factor => . LPAREN sum RPAREN @ 0',
        'factor => . NUMBER @ 0'
      ]
      set1 = [ # 1 . + (2 * 3 - 4)
        'factor => NUMBER . @ 0',
        'product => factor . @ 0',
        'sum => product . @ 0',
        # 'product => product . STAR factor @ 0',
        # 'product => product . SLASH factor @ 0',
        'p => sum . @ 0',
        'sum => sum . PLUS product @ 0'
        # 'sum => sum . MINUS product @ 0'
      ]
      set2 = [ # 1 + . (2 * 3 - 4)
        'sum => sum PLUS . product @ 0',
        'product => . product STAR factor @ 2',
        'product => . product SLASH factor @ 2',
        'product => . factor @ 2',
        'factor => . LPAREN sum RPAREN @ 2'
        # 'factor => . NUMBER @ 2'
      ]
      set3 = [ # 1 + (. 2 * 3 - 4)
        'factor => LPAREN . sum RPAREN @ 2',
        'sum => . sum PLUS product @ 3',
        'sum => . sum MINUS product @ 3',
        'sum => . product @ 3',
        'product => . product STAR factor @ 3',
        'product => . product SLASH factor @ 3',
        'product => . factor @ 3',
        # 'factor => . LPAREN sum RPAREN @ 3',
        'factor => . NUMBER @ 3'
      ]
      set4 = [ # 1 + (2 . * 3 - 4)
        'factor => NUMBER . @ 3',
        'product => factor . @ 3',
        'sum => product . @ 3',
        'product => product . STAR factor @ 3'
        # 'product => product . SLASH factor @ 3',
        # 'factor => LPAREN sum . RPAREN @ 2',
        # 'sum => sum . PLUS product @ 3',
        # 'sum => sum . MINUS product @ 3'
      ]
      set5 = [ # 1 + (2 * . 3 - 4)
        'product => product STAR . factor @ 3',
        # 'factor => . LPAREN sum RPAREN @ 5',
        'factor => . NUMBER @ 5'
      ]
      set6 = [ # 1 + (2 * 3 . - 4)
        'factor => NUMBER . @ 5',
        'product => product STAR factor . @ 3',
        'sum => product . @ 3',
        # 'product => product . STAR factor @ 3',
        # 'product => product . SLASH factor @ 3',
        # 'factor => LPAREN sum . RPAREN @ 2',
        # 'sum => sum . PLUS product @ 3',
        'sum => sum . MINUS product @ 3'
      ]
      set7 = [ # 1 + (2 * 3  - . 4)
        'sum => sum MINUS . product @ 3',
        'product => . product STAR factor @ 7',
        'product => . product SLASH factor @ 7',
        'product => . factor @ 7',
        # 'factor => . LPAREN sum RPAREN @ 7',
        'factor => . NUMBER @ 7'
      ]
      set8 = [ # 1 + (2 * 3 - 4 .)
        'factor => NUMBER . @ 7',
        'product => factor . @ 7',
        'sum => sum MINUS product . @ 3',
        # 'product => product . STAR factor @ 7',
        # 'product => product . SLASH factor @ 7',
        'factor => LPAREN sum . RPAREN @ 2'
        # 'sum => sum . PLUS product @ 3',
        # 'sum => sum . MINUS product @ 3'
      ]
      set9 = [ # 1 + (2 * 3 - 4 ).
        'factor => LPAREN sum RPAREN . @ 2',
        'product => factor . @ 2',
        'sum => sum PLUS product . @ 0',
        # 'product => product . STAR factor @ 2',
        # 'product => product . SLASH factor @ 2',
        'p => sum . @ 0'
        # 'sum => sum . PLUS product @ 0',
        # 'sum => sum . MINUS product @ 0'
      ]
      expectations = [set0, set1, set2, set3, set4, set5, set6, set7, set8, set9]
      expectations.each_with_index do |set, rank|
        expect(chart[rank].to_s).to eq(set.join("\n"))
      end
    end
  end # context

  context 'Handle empty rules' do
    it 'can cope with an empty rule' do
      recognizer = described_class.new(grammar_l7, tokenizer_l7)
      chart = recognizer.run('a a')
      expect(chart).to be_successful

      set0 = [ # . a a
        'S => . S T @ 0',
        'S => . a @ 0'
      ]
      set1 = [ # a . a
        'S => a . @ 0',
        'S => S . T @ 0',
        'T => . a B @ 1',
        'T => . a @ 1'
      ]
      set2 = [ # a a .
        'T => a . B @ 1',
        'T => a . @ 1',
        'B => . @ 2',
        'T => a B . @ 1',
        'S => S T . @ 0',
        'S => S . T @ 0'
        # 'T => . a B @ 2',
        # 'T => . a @ 2'
      ]

      expectations = [set0, set1, set2]
      comp_expected_actuals(chart, expectations)
    end

    it 'can cope with a nullable symbol' do
      recognizer = described_class.new(grammar_l14, tokenizer_l14)
      chart = recognizer.run('a a / a')
      expect(chart).to be_successful

      set0 = [ # . a a / a
        'S => . E @ 0',
        'E => . E Q F @ 0',
        'E => . F @ 0',
        'F => . a @ 0'
      ]
      set1 = [ # a . a / a
        'F => a . @ 0',
        'E => F . @ 0',
        'S => E . @ 0',
        'E => E . Q F @ 0',
        # 'Q => . star @ 1',
        # 'Q => . slash @ 1',
        'Q => . @ 1',
        'E => E Q . F @ 0',
        'F => . a @ 1'
      ]
      set2 = [ # a a . / a
        'F => a . @ 1',
        'E => E Q F . @ 0',
        'S => E . @ 0',
        'E => E . Q F @ 0',
        # 'Q => . star @ 2',
        'Q => . slash @ 2',
        'Q => . @ 2',
        'E => E Q . F @ 0'
        # 'F => . a @ 2'
      ]
      set3 = [ # a a . / a
        'Q => slash . @ 2',
        'E => E Q . F @ 0',
        'F => . a @ 3'
      ]
      set4 = [ # a a / . a
        'F => a . @ 3',
        'E => E Q F . @ 0',
        'S => E . @ 0',
        'E => E . Q F @ 0',
        # 'Q => . star @ 4',
        # 'Q => . slash @ 4',
        'Q => . @ 4',
        'E => E Q . F @ 0'
        # 'F => . a @ 4'
      ]
      expectations = [set0, set1, set2, set3, set4]
      comp_expected_actuals(chart, expectations)
    end
  end # context

  context 'Recognizer and ambiguous grammars:' do
    it 'can handle ambiguous input (I)' do
      recognizer = described_class.new(grammar_l31, tokenizer_l1)
      chart = recognizer.run('2 + 3 * 4')
      expect(chart).to be_successful

      set0 = [ # . 2 + 3 * 4
        'p => . s @ 0',
        's => . s PLUS s @ 0',
        's => . s STAR s @ 0',
        's => . INTEGER @ 0'
      ]
      set1 = [ # 2 . + 3 * 4
        's => INTEGER . @ 0',
        'p => s . @ 0',
        's => s . PLUS s @ 0'
        # 's => s . STAR s @ 0',
      ]
      set2 = [ # 2 + . 3 * 4
        's => s PLUS . s @ 0',
        's => . s PLUS s @ 2',
        's => . s STAR s @ 2',
        's => . INTEGER @ 2'
      ]
      set3 = [ # 2 + 3 . * 4
        's => INTEGER . @ 2',
        's => s PLUS s . @ 0',
        # 's => s . PLUS s @ 2',
        's => s . STAR s @ 2',
        'p => s . @ 0',
        # 's => s . PLUS s @ 0',
        's => s . STAR s @ 0'
      ]
      set4 = [ # 2 + 3 * . 4
        's => s STAR . s @ 2',
        's => s STAR . s @ 0',
        's => . s PLUS s @ 4',
        's => . s STAR s @ 4',
        's => . INTEGER @ 4'
      ]
      set5 = [ # 2 + 3 * 4 .
        's => INTEGER . @ 4',
        's => s STAR s . @ 2',
        's => s STAR s . @ 0',
        # 's => s . PLUS s @ 4',
        # 's => s . STAR s @ 4',
        's => s PLUS s . @ 0',
        # 's => s . PLUS s @ 2',
        # 's => s . STAR s @ 2',
        'p => s . @ 0'
        # 's => s . PLUS s @ 0',
        # 's => s . STAR s @ 0'
      ]
      expectations = [set0, set1, set2, set3, set4, set5]
      comp_expected_actuals(chart, expectations)
    end

    it 'can handle ambiguous input (II)' do
      recognizer = described_class.new(grammar_l4, tokenizer_l4)
      chart = recognizer.run('abc + def + ghi')
      expect(chart).to be_successful

      set0 = [ # . abc + def + ghi
        'S => . E @ 0',
        'E => . E plus E @ 0',
        'E => . id @ 0'
      ]
      set1 = [ # abc . + def + ghi
        'E => id . @ 0',
        'S => E . @ 0',
        'E => E . plus E @ 0'
      ]
      set2 = [ # abc + . def + ghi
        'E => E plus . E @ 0',
        'E => . E plus E @ 2',
        'E => . id @ 2'
      ]
      set3 = [ # abc + def . + ghi
        'E => id . @ 2',
        'E => E plus E . @ 0',
        'E => E . plus E @ 2',
        'S => E . @ 0',
        'E => E . plus E @ 0'

      ]
      set4 = [ # abc + def + . ghi
        'E => E plus . E @ 2',
        'E => E plus . E @ 0',
        'E => . E plus E @ 4',
        'E => . id @ 4'
      ]
      set5 = [ # abc + def + ghi .
        'E => id . @ 4',
        'E => E plus E . @ 2',
        'E => E plus E . @ 0',
        # 'E => E . plus E @ 4',
        # 'E => E . plus E @ 2',
        'S => E . @ 0'
        # 'E => E . plus E @ 0'
      ]
      expectations = [set0, set1, set2, set3, set4, set5]
      comp_expected_actuals(chart, expectations)
    end

    it 'copes with the dangling else ambiguity' do
      recognizer = described_class.new(grammar_l6, tokenizer_l6)
      chart = recognizer.run('if E then if E then other else other')
      expect(chart).to be_successful
    end

    it 'swallows an input that failed with the Earley parsing approach' do
      recognizer = described_class.new(grammar_l8, tokenizer_l8)
      chart = recognizer.run('x x x')
      expect(chart).to be_successful

      set0 = [ # . x x x
        'S => . S S @ 0',
        'S => . x @ 0'
      ]
      set1 = [ # x . x x
        'S => x . @ 0',
        'S => S . S @ 0',
        'S => . S S @ 1',
        'S => . x @ 1'
      ]
      set2 = [ # x x . x
        'S => x . @ 1',
        'S => S S . @ 0',
        'S => S . S @ 1',
        'S => S . S @ 0',
        'S => . S S @ 2',
        'S => . x @ 2'
      ]
      set3 = [ # x x x .
        'S => x . @ 2',
        'S => S S . @ 1',
        'S => S S . @ 0',
        'S => S . S @ 2',
        'S => S . S @ 1',
        'S => S . S @ 0',
        'S => . S S @ 3'
        # 'S => . x @ 3'
      ]
      expectations = [set0, set1, set2, set3]
      comp_expected_actuals(chart, expectations)
    end


    it 'accepts an input with multiple levels of ambiguity' do
      recognizer = described_class.new(grammar_l8, tokenizer_l8)
      chart = recognizer.run('x x x x')
      expect(chart).to be_successful

      set0 = [ # . x x x x
        'S => . S S @ 0',
        'S => . x @ 0'
      ]
      set1 = [ # x . x x x
        'S => x . @ 0',
        'S => S . S @ 0',
        'S => . S S @ 1',
        'S => . x @ 1'
      ]
      set2 = [ # x x . x x
        'S => x . @ 1',
        'S => S S . @ 0',
        'S => S . S @ 1',
        'S => S . S @ 0',
        'S => . S S @ 2',
        'S => . x @ 2'
      ]
      set3 = [ # x x x . x
        'S => x . @ 2',
        'S => S S . @ 1',
        'S => S S . @ 0',
        'S => S . S @ 2',
        'S => S . S @ 1',
        'S => S . S @ 0',
        'S => . S S @ 3',
        'S => . x @ 3'
      ]
      set4 = [ # x x x x .
        'S => x . @ 3',
        'S => S S . @ 2',
        'S => S S . @ 1',
        'S => S S . @ 0', # Success entry
        'S => S . S @ 3',
        'S => S . S @ 2',
        'S => S . S @ 1',
        'S => S . S @ 0',
        'S => . S S @ 4'
      ]
      expectations = [set0, set1, set2, set3, set4]
      comp_expected_actuals(chart, expectations)
    end

    it 'swallows the input from an infinite ambiguity grammar' do
      recognizer = described_class.new(grammar_l9, tokenizer_l9)
      chart = recognizer.run('x x x')
      expect(chart).to be_successful

      set0 = [ # . x x x
        'S => . S S @ 0',
        'S => . @ 0',
        'S => . x @ 0',
        'S => S . S @ 0',
        'S => S S . @ 0'
      ]
      set1 = [ # x . x x
        'S => x . @ 0',
        'S => S . S @ 0',
        'S => S S . @ 0',
        'S => . S S @ 1',
        'S => . @ 1',
        'S => . x @ 1',
        'S => S . S @ 1',
        'S => S S . @ 1'
      ]
      set2 = [ # x x . x
        'S => x . @ 1',
        'S => S S . @ 0',
        'S => S . S @ 1',
        'S => S S . @ 1',
        'S => S . S @ 0',
        'S => . S S @ 2',
        'S => . @ 2',
        'S => . x @ 2',
        'S => S . S @ 2',
        'S => S S . @ 2'
      ]
      set3 = [ # x x x .
        'S => x . @ 2',
        'S => S S . @ 1',
        'S => S S . @ 0',
        'S => S . S @ 2',
        'S => S S . @ 2',
        'S => S . S @ 1',
        'S => S . S @ 0',
        'S => . S S @ 3',
        'S => . @ 3',
        # 'S => . x @ 3',
        'S => S . S @ 3',
        'S => S S . @ 3'
      ]
      expectations = [set0, set1, set2, set3]
      comp_expected_actuals(chart, expectations)
    end
  end # context

  context 'Recognizer and recursive rules:' do
    it 'can handle left-recursion' do
      recognizer = described_class.new(grammar_l10, tokenizer_l10)
      chart = recognizer.run('a a a a a')
      expect(chart).to be_successful

      set0 = [ # . a a a a a
        'A => . A a @ 0',
        'A => . @ 0',
        'A => A . a @ 0'
      ]
      set1 = [ # a . a a a a
        'A => A a . @ 0',
        'A => A . a @ 0'
      ]
      set2 = [ # a a . a a a
        'A => A a . @ 0',
        'A => A . a @ 0'
      ]
      set3 = [ # a a a . a a
        'A => A a . @ 0',
        'A => A . a @ 0'
      ]
      set4 = [ # a a a a . a
        'A => A a . @ 0',
        'A => A . a @ 0'
      ]
      set5 = [ # a a a a a .
        'A => A a . @ 0'
        # 'A => A . a @ 0'
      ]
      expectations = [set0, set1, set2, set3, set4, set5]
      comp_expected_actuals(chart, expectations)
    end

    it 'supports right-recursive rules' do
      recognizer = described_class.new(grammar_l11, tokenizer_l11)
      chart = recognizer.run('a a a a a')
      expect(chart).to be_successful
      set0 = [ # . a a a a a
        'A => . a A @ 0',
        'A => . @ 0'
      ]
      set1 = [ # a . a a a a
        'A => a . A @ 0',
        'A => . a A @ 1',
        'A => . @ 1',
        'A => a A . @ 0'
      ]
      set2 = [ # a a . a a a
        'A => a . A @ 1',
        'A => . a A @ 2',
        'A => . @ 2',
        'A => a A . @ 1',
        'A => a A . @ 0'
      ]
      set3 = [ # a a a . a a
        'A => a . A @ 2',
        'A => . a A @ 3',
        'A => . @ 3',
        'A => a A . @ 2',
        'A => a A . @ 1',
        'A => a A . @ 0'
      ]
      set4 = [ # a a a a . a
        'A => a . A @ 3',
        'A => . a A @ 4',
        'A => . @ 4',
        'A => a A . @ 3',
        'A => a A . @ 2',
        'A => a A . @ 1',
        'A => a A . @ 0'
      ]
      set5 = [ # a a a a a .
        'A => a . A @ 4',
        # 'A => . a A @ 5',
        'A => . @ 5',
        'A => a A . @ 4',
        'A => a A . @ 3',
        'A => a A . @ 2',
        'A => a A . @ 1',
        'A => a A . @ 0'
      ]
      expectations = [set0, set1, set2, set3, set4, set5]
      comp_expected_actuals(chart, expectations)
    end

    it 'supports mid-recursive rules' do
      recognizer = described_class.new(grammar_l5, tokenizer_l5)
      chart = recognizer.run('a a b c c')
      expect(chart).to be_successful
      set0 = [ # . a a b c c
        'S => . A @ 0',
        'A => . a A c @ 0'
        # 'A => . b @ 0'
      ]
      set1 = [ # a . a b c c
        'A => a . A c @ 0',
        'A => . a A c @ 1'
        # 'A => . b @ 1'
      ]
      set2 = [ # a a . b c c
        'A => a . A c @ 1',
        # 'A => . a A c @ 2',
        'A => . b @ 2'
      ]
      set3 = [ # a a b . c c
        'A => b . @ 2',
        'A => a A . c @ 1'
      ]
      set4 = [ # a a b c . c
        'A => a A c . @ 1',
        'A => a A . c @ 0'
      ]
      set5 = [ # a a b c c .
        'A => a A c . @ 0',
        'S => A . @ 0'
      ]
      expectations = [set0, set1, set2, set3, set4, set5]
      comp_expected_actuals(chart, expectations)
    end

    it 'can handle hidden left-recursion' do
      recognizer = described_class.new(grammar_l12, tokenizer_l12)
      chart = recognizer.run('a b b b')
      expect(chart).to be_successful

      set0 = [ # . a b b b
        'S => . A T @ 0',
        'S => . a T @ 0',
        'A => . a @ 0',
        'A => . B A @ 0',
        'B => . @ 0',
        'A => B . A @ 0'
      ]
      set1 = [ # a . b b b
        'S => a . T @ 0',
        'A => a . @ 0',
        'T => . b b b @ 1',
        'S => A . T @ 0',
        'A => B A . @ 0'
      ]
      set2 = [ # a b . b b
        'T => b . b b @ 1'
      ]
      set3 = [ # a b b . b
        'T => b b . b @ 1'
      ]
      set4 = [ # a b b b .
        'T => b b b . @ 1',
        'S => a T . @ 0',
        'S => A T . @ 0'
      ]
      expectations = [set0, set1, set2, set3, set4]
      comp_expected_actuals(chart, expectations)
    end

    it 'can handle right-recursion (II)' do
      recognizer = described_class.new(grammar_l13, tokenizer_l13)
      chart = recognizer.run('x x x')
      expect(chart).to be_successful
      set0 = [ # . x x x
        'A => . x A @ 0',
        'A => . x @ 0'
      ]
      set1 = [ # x . x x
        'A => x . A @ 0',
        'A => x . @ 0',
        'A => . x A @ 1',
        'A => . x @ 1'
      ]
      set2 = [ # x x . x
        'A => x . A @ 1',
        'A => x . @ 1',
        'A => . x A @ 2',
        'A => . x @ 2',
        'A => x A . @ 0'
      ]
      set3 = [ # x x x .
        'A => x . A @ 2',
        'A => x . @ 2',
        # 'A => . x A @ 3',
        # 'A => . x @ 3',
        'A => x A . @ 1',
        'A => x A . @ 0'
      ]
      expectations = [set0, set1, set2, set3]
      comp_expected_actuals(chart, expectations)
    end

    # TODO: Use grammars from "The Structure of Shared Forests in Ambiguous Parsing"
    # Grammar UBDA == grammar_l8
    # Grammar RR == grammar_l13
  end # context

  context 'Error reporting:' do
    it 'should parse an invalid simple input' do
      recognizer = described_class.new(grammar_l5, tokenizer_l5)
      # Parse an erroneous input (b is missing)
      chart = recognizer.run('a a c c')
      expect(chart).not_to be_successful

      # TODO
      #       err_msg = <<-MSG
      # Syntax error at or near token line 1, column 5 >>>c<<<
      # Expected one of: ['a', 'b'], found a 'c' instead.
      #       MSG
      #       expect(parse_result.failure_reason.message).to eq(err_msg.chomp)
    end
  end # context

  context 'Error at start of input' do
    it 'raises an error if input is empty and grammar disallows this' do
      err_msg = 'Error: Input may not be empty nor blank.'
      recognizer = described_class.new(grammar_l5, tokenizer_l5)

      ['', "  \t  \n"].each do |input|
        chart = recognizer.run(input)
        expect(chart).not_to be_successful
        expect(chart.failure_class).to eq(StandardError)
        expect(chart.failure_reason).to eq(err_msg)
      end
    end

    it 'raises an error if encounters an unexpected token' do
      recognizer = described_class.new(grammar_l5, tokenizer_l5)
      chart = recognizer.run('a a c c')
      expect(chart).not_to be_successful
      set0 = [ # . a a c c
        'S => . A @ 0',
        'A => . a A c @ 0'
        # 'A => . b @ 0'
      ]
      set1 = [ # a . a c c
        'A => a . A c @ 0',
        'A => . a A c @ 1'
        # 'A => . b @ 1'
      ]
      set2 = [ # a a . c c
        'A => a . A c @ 1',
        'A => . a A c @ 2', # State is not pruned (in error state)
        'A => . b @ 2' # State is not pruned (in error state)
      ]
      [set0, set1, set2].each_with_index do |set, rank|
        expect(chart[rank].to_s).to eq(set.join("\n"))
      end
      expect(chart.failure_class).to eq(StandardError)
      err_msg = 'Syntax error at or near token line 1, column 5 >>>c<<< Expected one of: [a, b], found a c instead.'
      expect(chart.failure_reason).to eq(err_msg)
    end

    it "reports an error when last token isn't final state" do
      recognizer = described_class.new(grammar_l5, tokenizer_l5)
      chart = recognizer.run('aabc')
      expect(chart).not_to be_successful
      set0 = [ # . a a b c
        'S => . A @ 0',
        'A => . a A c @ 0'
        # 'A => . b @ 0'
      ]
      set1 = [ # a . a b c
        'A => a . A c @ 0',
        'A => . a A c @ 1'
        # 'A => . b @ 1'
      ]
      set2 = [ # a a . b c
        'A => a . A c @ 1',
        # 'A => . a A c @ 2',
        'A => . b @ 2'
      ]
      set3 = [ # a a b . c
        'A => b . @ 2',
        'A => a A . c @ 1'
      ]
      set4 = [ # a a b c .
        'A => a A c . @ 1',
        'A => a A . c @ 0'
      ]
      [set0, set1, set2, set3, set4].each_with_index do |set, rank|
        expect(chart[rank].to_s).to eq(set.join("\n"))
      end
      expect(chart.failure_class).to eq(StandardError)
      err_msg = "Line 1, column 4: Premature end of input after 'c', expected: c."
      expect(chart.failure_reason).to eq(err_msg)
    end
  end # context
end # describe
