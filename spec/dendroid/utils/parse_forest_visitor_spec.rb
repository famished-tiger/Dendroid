# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../support/sample_grammars'
require_relative '../../../lib/dendroid/recognizer/recognizer'
require_relative '../../../lib/dendroid/utils/parse_forest_visitor'

RSpec.describe Dendroid::Parsing::ParseForestVisitor do
  include SampleGrammars

  def build_parse_forest(source)
    recognizer = Dendroid::Recognizer::Recognizer.new(grammar_l8, tokenizer_l8)
    chart = recognizer.run(source)
    parser = Dendroid::Parsing::ParseResultBuilder.new
    parser.run(chart)
  end

  let(:root) { build_parse_forest('x x x x') }
  let(:output) { StringIO.new }
  let(:subscriber) { Dendroid::Parsing::ParseForestDOTRenderer.new(output) }
  subject { described_class.new(root) }

  context 'Initialization:' do
    it 'should be initialized with the forest root node' do
      expect { described_class.new(root) }.not_to raise_error
    end
  end # context

  context 'Parse forest visiting:' do
    it 'visits the nodes in bfs fashion' do
      subject.bfs_visit(subscriber)
      puts output.string
    end
  end # context
end # describe