# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells
  module Matchers
    # Match cell against a Ruby-like numeric comparison or a numeric constant
    class Numeric < Matcher
      # For example: >= 100 or != 0
      COMPARISON = /\A(?<comparator><=|>=|<|>|!=|:=|==|=)\s*(?<value>\S.*)\z/

      # Coerce the input value to a numeric representation before invoking the comparison.
      # If the coercion fails, it will produce a nil value which always fails to match.
      COMPARATORS = {
        '>'  => proc { |numeric_cell, value| Matchers.numeric(value)&.> numeric_cell },
        '>=' => proc { |numeric_cell, value| Matchers.numeric(value)&.>= numeric_cell },
        '<'  => proc { |numeric_cell, value| Matchers.numeric(value)&.< numeric_cell },
        '<=' => proc { |numeric_cell, value| Matchers.numeric(value)&.<= numeric_cell },
        '!=' => proc { |numeric_cell, value| Matchers.numeric(value)&.!= numeric_cell }
      }.freeze

      def self.match?(cell)
        match = COMPARISON.match(cell)
        return false unless match

        numeric_cell = Matchers.numeric(match['value'])
        return false unless numeric_cell

        comparator = match['comparator']

        # If the comparator is assignment/equality, then just treat as a simple constant
        proc = Constant.numeric?(operator: comparator, cell: numeric_cell)
        return proc if proc

        Proc.with(type: :proc,
                  function: COMPARATORS[comparator].curry[numeric_cell])
      end

      def matches?(cell)
        Numeric.match?(cell)
      end
    end
  end
end