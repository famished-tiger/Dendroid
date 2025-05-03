# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\syntax\symbol_empty'

describe Dendroid::Syntax::SymbolEmpty do
  subject { described_class.instance }

  context 'Provided services:' do
    it 'is frozen' do
      expect(subject).to be_frozen
    end

    it 'knows its default name' do
      expect(subject.name).to eq(:epsilon)
    end

    it 'knows it is a terminal symbol' do
      expect(subject.terminal?).to be_truthy
    end

    it 'is nullable' do
      expect(subject).to be_nullable
    end

    it 'is not productive (generative)' do
      expect(subject).not_to be_productive
    end
  end # context
end # describe
