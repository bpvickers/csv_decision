# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Recognise Ruby-like numeric comparison expressions.
  module Numeric
    # For example: >= 100 or != 0
    COMPARISON = /\A(?<comparator><=|>=|<|>|!=)\s*(?<value>\S.*)\z/
    private_constant :COMPARISON

    # Coerce the input value to a numeric representation before invoking the comparison.
    # If the coercion fails, it will produce a nil value which always fails to match.
    COMPARATORS = {
      '>'  => proc { |numeric_cell, value| Matchers.numeric(value)&.>  numeric_cell },
      '>=' => proc { |numeric_cell, value| Matchers.numeric(value)&.>= numeric_cell },
      '<'  => proc { |numeric_cell, value| Matchers.numeric(value)&.<  numeric_cell },
      '<=' => proc { |numeric_cell, value| Matchers.numeric(value)&.<= numeric_cell },
      '!=' => proc { |numeric_cell, value| Matchers.numeric(value)&.!= numeric_cell }
    }.freeze
    private_constant :COMPARATORS

    # @param (see Matchers::Matcher#matches?)
    # @return (see Matchers::Matcher#matches?)
    def self.matches?(cell)
      match = COMPARISON.match(cell)
      return false unless match

      numeric_cell = Matchers.to_numeric(match['value'])
      return false unless numeric_cell

      comparator = match['comparator']
      Proc.with(type: :proc,
                function: COMPARATORS[comparator].curry[numeric_cell].freeze)
    end
  end
end