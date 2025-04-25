# frozen_string_literal: true

require 'ostruct'
require_relative '../../spec_helper'
require_relative '../../../lib/dendroid/parsing/swapping_queue'

RSpec.describe Dendroid::Parsing::SwappingQueue do
  # quadruplet: [thread_id, algo, prev_element, element]
  let(:algo_tester) { ->(quad) { quad[1] == :scanner } }
  let(:comparator) { ->(previous, quad) { previous == quad[2] } }

  subject { described_class.new(3, algo_tester, comparator) }

  context 'Initialization:' do
    it 'is initialized without argument' do
      expect { described_class.new(3, algo_tester, comparator) }.not_to raise_error
    end

    it 'is empty at start' do
      expect(subject).to be_empty
      expect(subject.size).to be_zero
    end
  end # context

  context 'Queueing behaviour' do
    let(:element_a) { [1, :dummy, double('a'), 'a'] }
    let(:element_b) { [1, :dummy, double('b'), 'b'] }
    let(:element_c) { [1, :dummy, double('c'), 'c'] }
    let(:element_d) { [1, :dummy, double('d'), 'd'] }
    let(:element_ee) { [1, :scanner, double('ee'), 'ee'] }
    let(:element_ff) { [1, :scanner, double('ff'), 'ff'] }

    it 'inserts elements to main queue' do
      subject.enqueue(element_a)
      expect(subject.size).to eq(1)
      expect(subject.peek).to equal(element_a)
      subject.enqueue(element_b)
      expect(subject.size).to eq(2)
      subject.enqueue(element_c)
      expect(subject.size).to eq(3)
      expect(subject.peek).to equal(element_a)
      expect(subject.queue).to contain_exactly(element_a, element_b, element_c)
    end

    it 'inserts elements to lobby queue' do
      subject.enqueue(element_ee)
      expect(subject.size).to eq(1)
      subject.enqueue(element_ff)
      expect(subject.size).to eq(2)
      expect(subject.lobby).to contain_exactly(element_ee, element_ff)

      subject.enqueue(element_a)
      expect(subject.size).to eq(3)
      expect(subject.peek).to equal(element_a)
    end

    it 'dequeues from main queue first, then the lobby one' do
      subject.enqueue(element_a)
      subject.enqueue(element_b)
      subject.enqueue(element_c)
      subject.enqueue(element_ee)
      subject.enqueue(element_ff)
      expect(subject.size).to eq(5)

      expect(subject.dequeue).to equal(element_a)
      expect(subject.size).to eq(4)
      expect(subject.dequeue).to equal(element_b)
      expect(subject.size).to eq(3)
      expect(subject.dequeue).to equal(element_c)
      expect(subject.size).to eq(2)
      expect(subject.dequeue).to equal(element_ee)
      expect(subject.size).to eq(1)
      expect(subject.dequeue).to equal(element_ff)
      expect(subject.size).to be_zero
    end
  end # context
end # describe