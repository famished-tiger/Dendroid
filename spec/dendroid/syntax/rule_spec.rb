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

  context 'Errors:' do
    it 'fails when initialized with a terminal' do
      msg = "Terminal symbol 'NUMBER' may not be on left-side of a rule."
      expect { described_class.new(num_symb) }.to raise_error(StandardError, msg)
    end
  end
end # describe
