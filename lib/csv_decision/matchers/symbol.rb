# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Recognise expressions in table data cells.
  class Matchers
    # Match cell against a symbolic expression - e.g., :column, > :column
    class Symbol < Matcher
      # @param (see Matcher#matches?)
      # @return (see Matcher#matches?)
      def matches?(cell)
        CSVDecision::Symbol.matches?(cell)
      end
    end
  end
end