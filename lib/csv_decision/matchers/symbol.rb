# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Recognise expressions in table data cells.
  class Matchers
    # Match cell against a
    #   * cell constant - e.g., := true, = nil
    #   * symbolic expression - e.g., :column, > :column
    class Symbol < Matcher
      # @param (see Matchers::Matcher#matches?)
      # @return (see Matchers::Matcher#matches?)
      def matches?(cell)
        CSVDecision::Symbol.matches?(cell)
      end
    end
  end
end