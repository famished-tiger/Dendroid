# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/dendroid/lexical/token_position'

describe Dendroid::Lexical::TokenPosition do
  let(:ex_lineno) { 5 }
  let(:ex_column) { 7 }

  subject { described_class.new(ex_lineno, ex_column) }

  context 'Initialization:' do
    it 'is initialized with a line number and a column position' do
      expect { described_class.new(ex_lineno, ex_column) }.not_to raise_error
    end

    it 'knows its line number' do
      expect(subject.lineno).to eq(ex_lineno)
    end

    it 'knows its column number' do
      expect(subject.column).to eq(ex_column)
    end
  end # context

  context 'Provided services:' do
    it 'renders a String representation of itself' do
      expect(subject.to_s).to eq("#{ex_lineno}:#{ex_column}")
    end
  end # context
end # describe