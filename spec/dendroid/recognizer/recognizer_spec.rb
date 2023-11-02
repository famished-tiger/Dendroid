# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../support/sample_grammars'
require_relative '../../../lib/dendroid/recognizer/recognizer'

describe Dendroid::Recognizer::Recognizer do
  include SampleGrammars
  let(:grammar1) { grammar_l1 }

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
        #'m => m . STAR t @ 0',
        'p => s . @ 0',
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
        'p => s . @ 0',
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
        'sum => sum . PLUS product @ 0',
      # 'sum => sum . MINUS product @ 0'
      ]
      set2 = [ # 1 + . (2 * 3 - 4)
        'sum => sum PLUS . product @ 0',
        'product => . product STAR factor @ 2',
        'product => . product SLASH factor @ 2',
        'product => . factor @ 2',
        'factor => . LPAREN sum RPAREN @ 2',
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
        'product => product . STAR factor @ 3',
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
        'factor => LPAREN sum . RPAREN @ 2',
      # 'sum => sum . PLUS product @ 3',
      # 'sum => sum . MINUS product @ 3'
      ]
      set9 = [ # 1 + (2 * 3 - 4 ).
        'factor => LPAREN sum RPAREN . @ 2',
        'product => factor . @ 2',
        'sum => sum PLUS product . @ 0',
        # 'product => product . STAR factor @ 2',
        # 'product => product . SLASH factor @ 2',
        'p => sum . @ 0',
      # 'sum => sum . PLUS product @ 0',
      # 'sum => sum . MINUS product @ 0'
      ]
      expectations = [set0, set1, set2, set3, set4, set5, set6, set7, set8, set9]
      expectations.each_with_index do |set, rank|
        expect(chart[rank].to_s).to eq(set.join("\n"))
      end
    end
  end # context
end # describe
