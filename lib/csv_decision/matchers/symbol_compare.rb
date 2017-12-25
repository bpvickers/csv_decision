# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells
  module Matchers
    # Match cell against a
    #   * cell constant - e.g., := true, = nil
    #   * symbolic expression - e.g., :column, > :column
    class SymbolCompare < Matcher
      # Looks like a function call or symbol expressions, e.g.,
      # := function(arg: symbol)
      # == :column_name
      def matches?(cell)
        CSVDecision::Symbol.matches?(cell)
      end
    end
  end
end