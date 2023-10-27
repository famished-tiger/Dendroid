# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\syntax\non_terminal'

describe Dendroid::Syntax::NonTerminal do
  let(:sample_nonterminal_name) { 'EXPRESSION' }

  subject { described_class.new(sample_nonterminal_name) }

  context 'Provided services:' do
    it 'knows it is not a terminal symbol' do
      expect(subject.terminal?).to be_falsey
    end
  end # context
end # describe