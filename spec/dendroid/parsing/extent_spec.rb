# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/dendroid/parsing/extent'

RSpec.describe Dendroid::Parsing::Extent do
  subject { described_class.new(1, 3) }

  context 'Initialization' do
    it 'accepts two integer arguments' do
      expect { described_class.new(1, 3) }.not_to raise_error
    end

    it 'accepts an integer and array arguments' do
      expect { described_class.new(1, [1, 2]) }.not_to raise_error
    end

    it 'accepts an array and integer arguments' do
      expect { described_class.new([1, 2], 3) }.not_to raise_error
    end

    it 'accepts nil and an integer arguments' do
      expect { described_class.new(nil, 3) }.not_to raise_error
    end

    it 'knows its lower boundary' do
      expect(subject.lower). to eq(1)
      expect(subject.lower == subject.origin).to be_truthy
      expect(subject.lower == subject.begin).to be_truthy
    end

    it 'knows its upper boundary' do
      expect(subject.upper). to eq(3)
      expect(subject.upper == subject.end).to be_truthy
    end
  end # context

  context 'Provided services:' do
    def build_instance(low, high)
      described_class.new(low, high)
    end

    it 'compares with another instance for equality' do
      expect(subject).to eq(subject)
      expect(subject).to eq(build_instance(1, 3))
      expect(subject).not_to eq(build_instance(0, 4))
    end

    it 'renders a text representation of itself' do
      expect(subject.to_s).to eq('[1..3]')

      expect(build_instance(1, [1, 2]).to_s).to eq('[1..2-]')
      expect(build_instance([1, 2], 3).to_s).to eq('[1+..3]')
      expect(build_instance(nil, 3).to_s).to eq('[nil..3]')
    end
  end # context
end # describe
