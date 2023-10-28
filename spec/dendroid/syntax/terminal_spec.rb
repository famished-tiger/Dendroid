# frozen_string_literal: true

require_relative '..\..\spec_helper'
require_relative '..\..\..\lib\dendroid\syntax\terminal'

describe Dendroid::Syntax::Terminal do
  let(:sample_terminal_name) { 'INTEGER' }

  subject { described_class.new(sample_terminal_name) }

  context 'Provided services:' do
    it 'knows it is a terminal symbol' do
      expect(subject.terminal?).to be_truthy
    end

    it 'is frozen after initialization' do
      expect(subject).to be_frozen
    end

    it 'is not nullable' do
      expect(subject).not_to be_nullable
    end

    it 'is productive (generative)' do
      expect(subject).to be_productive
    end
  end # context
end # describe
