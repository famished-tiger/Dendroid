# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\lexical\token_position'
require_relative '..\..\..\lib\dendroid\lexical\literal'

describe Dendroid::Lexical::Literal do
  let(:ex_source) { '42' }
  let(:ex_pos) { Dendroid::Lexical::TokenPosition.new(2, 5) }
  let(:ex_terminal) { :INTEGER }
  let(:ex_value) { 42 }
  subject { described_class.new(ex_source, ex_pos, ex_terminal, ex_value) }

  context 'Initialization:' do
    it 'is initialized with a text, position, symbol name and value' do
      expect { described_class.new(ex_source, ex_pos, ex_terminal, ex_value) }.not_to raise_error
    end

    it 'knows its value' do
      expect(subject.value).to eq(ex_value)
    end
  end # context
end # describe
