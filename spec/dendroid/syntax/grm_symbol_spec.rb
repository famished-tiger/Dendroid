# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\syntax\grm_symbol'

describe Dendroid::Syntax::GrmSymbol do
  let(:sample_symbol_name) { 'INTEGER' }

  subject { described_class.new(sample_symbol_name) }

  context 'Initialization:' do
    it 'is initialized with a name as String' do
      expect { described_class.new(sample_symbol_name) }.not_to raise_error
    end

    it 'is initialized with a name as Symbol' do
      expect { described_class.new(:INTEGER) }.not_to raise_error
    end

    it 'raises an error if the symbol name is empty' do
      err_msg = 'A symbol name cannot be empty.'
      expect { described_class.new('') }.to raise_error(StandardError, err_msg)
    end
  end # context

  context 'Provided services:' do
    it 'knows its name as a Symbol' do
      expect(subject.name).to eq(sample_symbol_name.to_sym)
    end

    it 'renders a String representation of itself' do
      expect(subject.to_s).to eq(sample_symbol_name)
    end

    # rubocop: disable Lint/BinaryOperatorWithIdenticalOperands
    it 'can compare with another symbol' do
      expect(subject == subject).to be_truthy
      same = described_class.new(sample_symbol_name)
      expect(subject == same).to be_truthy
      different = described_class.new('NUMBER')
      expect(subject == different).to be_falsey
    end
    # rubocop: enable Lint/BinaryOperatorWithIdenticalOperands
  end # context
end # describe
