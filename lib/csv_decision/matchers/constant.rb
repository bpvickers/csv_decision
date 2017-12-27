# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells
  class Matchers
    # Cell constant matcher - e.g., := true, = nil.
    class Constant < Matcher
      # @param (see Matchers::Matcher)
      # @return (see Matchers::Matcher)
      def matches?(cell)
        CSVDecision::Constant.matches?(cell)
      end
    end
  end
end