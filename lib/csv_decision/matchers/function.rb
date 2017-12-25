# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells
  module Matchers
    # Match cell against a function call
    #   * no arguments - e.g., := present?
    #   * with arguments - e.g., :=lookup?(:table)
    # TODO: fully implement
    class Function < Matcher
      def initialize(options = {})
        @options = options
      end

      # Looks like a function call or symbol expressions, e.g.,
      # := function(arg: symbol)
      # == :column_name
      def matches?(cell)
        CSVDecision::Function.matches?(cell)
      end
    end
  end
end