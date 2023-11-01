# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/dendroid/utils/base_tokenizer'

describe Dendroid::Utils::BaseTokenizer do
  # Implements a dotted item: expression => NUMBER . PLUS NUMBER
  subject { described_class.new }

  context 'Initialization:' do
    it 'is initialized with an optional block' do
      expect { described_class.new }.not_to raise_error
    end

    it 'has a scanner at start' do
      expect(subject.scanner).to be_kind_of(StringScanner)
    end

    it 'initializes actions to defaults' do
      expect(subject.actions).to be_member(:skip_nl)
      expect(subject.actions).to be_member(:skip_ws)
    end
  end # context

  context 'Tokenizing:' do
    subject do
      described_class.new do
        scan_verbatim(['+', '*'])
        scan_value(/\d+/, :INTEGER, ->(txt) { txt.to_i })
        map_verbatim2terminal({ '+' => :PLUS, '*' => :STAR })
      end
    end

    it 'generates a sequence of tokens from a simple input' do
      subject.input = '2 + 3 * 4'

      expectations = [
        ['1:1', '2', :INTEGER, 2],
        ['1:3', '+', :PLUS, nil],
        ['1:5', '3', :INTEGER, 3],
        ['1:7', '*', :STAR, nil],
        ['1:9', '4', :INTEGER, 4]
      ]
      expectations.each do |tuple|
        tok = subject.next_token
        %i[pos_to_s source terminal value].each_with_index do |message, index|
          expect(tok.send(message)).to eq(tuple[index]) unless tuple[index].nil?
        end
      end

      # No more token... 'next_token' method returns nil
      expect(subject.next_token).to be_nil
    end
  end # context
end # describe
