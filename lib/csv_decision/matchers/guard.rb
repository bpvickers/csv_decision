# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Recognise expressions in table data cells.
  class Matchers
    # Match cell against a column symbol guard expression - e.g., +> :column.present?+ or +:column == 100.0+.
    class Guard < Matcher
      # @param (see Matcher#matches?)
      # @return (see Matcher#matches?)
      def matches?(cell)
        CSVDecision::Guard.matches?(cell)
      end
    end
  end
end