# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells
  module Matchers
    # Match cell against a cell constant - e.g., := true, = nil
    class Constant < Matcher

      def matches?(cell)
        CSVDecision::Constant.matches?(cell)
      end
    end
  end
end