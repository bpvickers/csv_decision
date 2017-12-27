# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells
  class Matchers
    # Recognise numeric comparison expressions - e.g., +> 100+ or +!= 0+
    class Numeric < Matcher
      # @param (see Matchers::Matcher#matches?)
      # @return (see Matchers::Matcher#matches?)
      def matches?(cell)
        CSVDecision::Numeric.matches?(cell)
      end
    end
  end
end