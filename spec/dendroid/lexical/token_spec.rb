# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/dendroid/lexical/token_position'
require_relative '../../../lib/dendroid/lexical/token'

describe Dendroid::Lexical::Token do
  let(:ex_source) { 'else' }
  let(:ex_pos) { Dendroid::Lexical::TokenPosition.new(2, 5) }
  let(:ex_terminal) { 'ELSE' }
  subject { described_class.new(ex_source, ex_pos, ex_terminal) }

  context 'Initialization:' do
    it 'is initialized with a text, position and symbol name' do
      expect { described_class.new(ex_source, ex_pos, ex_terminal) }.not_to raise_error
    end

    it 'knows its source text' do
      expect(subject.source).to eq(ex_source)
    end

    it 'knows its position' do
      expect(subject.position).to eq(ex_pos)
      expect(subject.pos_to_s).to eq('2:5')
    end

    it 'knows the terminal name' do
      expect(subject.terminal).to eq(ex_terminal)
    end

    it 'has no literal value attached to it' do
      expect(subject).not_to be_literal
    end
  end # context
end # describe
