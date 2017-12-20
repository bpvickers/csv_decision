# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells
  module Matchers
    # Match cell against a Ruby-like range
    class Range
      # Range types are .. or ...
      TYPE = '(\.\.\.|\.\.)'

      def self.range_re(value)
        Matchers.regexp(
          "(?<negate>#{Matchers::NEGATE}?)\\s*(?<min>#{value})(?<type>#{TYPE})(?<max>#{value})"
        )
      end

      NUMERIC_RANGE = range_re(Matchers::NUMERIC)

      # One or more alphanumeric characters
      ALNUM = '[[:alnum:]][[:alnum:]]*'
      ALNUM_RANGE = range_re(ALNUM)

      def self.convert(value, method)
        method ? Matchers.send(method, value) : value
      end

      def self.range(match, coerce: nil)
        negate = match['negate'] == Matchers::NEGATE
        min = convert(match['min'], coerce)
        type = match['type']
        max = convert(match['max'], coerce)

        [negate, type == '...' ? min...max : min..max]
      end

      def self.numeric_range(negate, range)
        return ->(value) { range.include?(Matchers.numeric(value)) } unless negate
        ->(value) { !range.include?(Matchers.numeric(value)) }
      end

      def self.alnum_range(negate, range)
        return ->(value) { range.include?(value) } unless negate
        ->(value) { !range.include?(value) }
      end

      def self.proc(match:, coerce: nil)
        negate, range = range(match, coerce: coerce)
        method = coerce ? :numeric_range : :alnum_range
        function = Range.send(method, negate, range)
        Proc.with(type: :proc, function: function)
      end

      def matches?(cell)
        if (match = NUMERIC_RANGE.match(cell))
          return Range.proc(match: match, coerce: :to_numeric)
        end

        if (match = ALNUM_RANGE.match(cell))
          return Range.proc(match: match)
        end

        false
      end
    end
  end
end