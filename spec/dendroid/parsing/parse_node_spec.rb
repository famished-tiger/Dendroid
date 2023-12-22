# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/dendroid/parsing/parse_node'

RSpec.describe Dendroid::Parsing::ParseNode do
  let(:sample_range) { 3..5 }
  subject { described_class.new(3, 5) }

  context 'Initialization:' do
    it 'should be initialized with two token positions' do
      expect { described_class.new(3, 5) }.not_to raise_error
    end

    it 'knows its origin and end positions' do
      expect(subject.range).to eq(sample_range)
    end
  end # context

  context 'Provided services:' do
    it 'renders a String representation of its range' do
      expect(subject.send(:range_to_s)).to eq('[3..5]')
    end
  end # context
end # describe
