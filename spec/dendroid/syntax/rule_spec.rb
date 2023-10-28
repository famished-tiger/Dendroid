# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\syntax\terminal'
require_relative '..\..\..\lib\dendroid\syntax\non_terminal'
require_relative '..\..\..\lib\dendroid\syntax\rule'

describe Dendroid::Syntax::Rule do
  let(:num_symb) { Dendroid::Syntax::Terminal.new('NUMBER') }
  let(:expr_symb) { Dendroid::Syntax::NonTerminal.new('expression') }

  subject { described_class.new(expr_symb) }

  context 'Initialization:' do
    it 'is initialized with a non-terminal' do
      expect { described_class.new(expr_symb) }.not_to raise_error
    end

    it 'knows its head (aka lhs)' do
      expect(subject.head).to eq(expr_symb)
    end
  end # context
end # describe
