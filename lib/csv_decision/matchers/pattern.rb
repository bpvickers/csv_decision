# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells
  module Matchers
    # Match cell on a regular expression pattern
    class Pattern < Matchers::Matcher
      def initialize(options: {})
        @regexp_implicit = options[:regexp_implicit]

        super
      end

      def match?(cell)
        return false if cell == ''

        comparator, value = Pattern.regexp?(cell: cell, implicit: @regexp_implicit)

        # No need to use a regexp if we just have a simple string
        return false unless comparator

        pattern = comparator == '!=' ? value : Pattern.regexp(value)

        proc = PATTERN_LAMBDAS[comparator].curry[pattern].freeze

        Proc.with(type: :proc, function: proc)
      end
    end
  end
end