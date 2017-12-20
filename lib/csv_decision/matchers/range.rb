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
        method ? Matchers.send(method, value) :  value
      end

      def self.range(match, coerce: nil)
        negate = match['negate'] == Matchers::NEGATE
        min = convert(match['min'], coerce)
        type = match['type']
        max = convert(match['max'], coerce)

        [negate, type == '...' ? min...max : min..max]
      end

      # def self.numeric_range(match)
      #   range(match, coerce: :to_numeric)
      # end

      def self.proc_numeric_range(match)
        negate, range = range(match, coerce: :to_numeric)
        return ->(value) { range.include?(Matchers.numeric(value)) } unless negate
        ->(value) { !range.include?(Matchers.numeric(value)) }
      end

      def self.proc_alnum_range(match)
        negate, range = range(match)
        return ->(value) { range.include?(value) } unless negate
        ->(value) { !range.include?(value) }
      end

      def matches?(cell)
        if (match = NUMERIC_RANGE.match(cell))
          return Range.proc_numeric_range(match)
        end

        if (match = ALNUM_RANGE.match(cell))
          return Range.proc_alnum_range(match)
        end

        false
      end
    end
  end
end