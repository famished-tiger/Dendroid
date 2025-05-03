# frozen_string_literal: true

module Dendroid
  module Parsing
    class EItemProxy < BasicObject
      attr_accessor :original
      attr_reader :ordering

      def initialize(e_item, index, overwrite = true)
        @original = e_item
        @ordering = index
        # @predecessors = index.nil? ? e_item.predecessors.dup : [e_item.predecessors[index]]
        # e_item.predecessors[index] = self if overwrite
      end

      def is_a?(klass)
        klass == EItemProxy
      end

      def hash
        __id__.hash
      end

      def ==(other)
        if other.is_a?(EItemProxy)
          __id__ == other.__id__
        else
          original == other
        end
      end

      # Return one or more predecessors from original EItem
      # @return [Array<Dendroid::Recognizer::EItem>]
      # def predecessors
      #   @predecessors
      # end

      def to_s
        'Proxy to ' + original.to_s
      end

      private

      def method_missing(name, *args)
        original.send(name, *args)
      end
    end # class
  end # module
end # module

