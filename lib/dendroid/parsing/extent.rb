# frozen_string_literal: true

module Dendroid
  module Parsing
    class Extent
      attr_reader :lower
      attr_reader :upper

      alias_method :origin, :lower
      alias_method :begin, :lower
      alias_method :end, :upper

      def initialize(low, high)
        @lower = valid_lower(low)
        @upper = valid_upper(high)
      end

      def ==(other)
        lower == other.lower && upper == other.upper
      end

      def definite?
        lower.is_a?(Integer) && upper.is_a?(Integer)
      end

      def definite_origin?
        lower.is_a?(Integer)
      end

      def to_s
        if lower.is_a? Array
          lower_str = "#{lower[0]}+"
        elsif lower.nil?
          lower_str = 'nil'
        else
          lower_str = lower.to_s
        end

        if upper.is_a? Array
          upper_str = "#{upper[-1]}-"
        else
          upper_str = upper.to_s
        end

        "[#{lower_str}..#{upper_str}]"
      end

      # Assumption: one of the extent covers the one other one or
      # they have both the same extent
      # Returns +1 if other is embedded in self.extent
      # Returns 0 if both extent are numerically the same
      # Returns -1 if self is embedded in other
      def innermost(other)
        return 0 if self == other

        my_diff = upper - lower
        its_diff = other.upper - other.lower

        my_diff > its_diff ? 1 : -1
      end

      private

      def valid_lower(low)
        validate_bound(low)
      end

      def valid_upper(high)
        validate_bound(high)
      end

      def validate_bound(bound)
        if bound.is_a? Array
          arr = bound.uniq.sort
          arr.size == 1 ? arr[0] : arr
        else
          bound
        end
      end
    end
  end # module
end # module

