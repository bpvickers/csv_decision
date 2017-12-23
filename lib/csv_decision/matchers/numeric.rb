# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells
  module Matchers
    # Match cell against a Ruby-like numeric comparison
    class Numeric < Matcher
      # Range types are .. or ...
      COMPARISON = /\A(?<comparator><=|>=|<|>|!=)\s*(?<value>\S.*)\z/

      COMPARATORS = {
        '>'  => proc { |numeric_cell, value| Matchers.numeric(value) &.>  numeric_cell },
        '>=' => proc { |numeric_cell, value| Matchers.numeric(value) &.>= numeric_cell },
        '<'  => proc { |numeric_cell, value| Matchers.numeric(value) &.<  numeric_cell },
        '<=' => proc { |numeric_cell, value| Matchers.numeric(value) &.<= numeric_cell },
        '!=' => proc { |numeric_cell, value| Matchers.numeric(value) &.!= numeric_cell }
      }.freeze

      def matches?(cell)
        match = COMPARISON.match(cell)
        return false unless match

        numeric_cell = Matchers.numeric(match['value'])
        return false unless numeric_cell

        Proc.with(type: :proc,
                  function: COMPARATORS[match['comparator']].curry[numeric_cell])
      end
    end
  end
end