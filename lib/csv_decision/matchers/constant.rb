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
      # If a constant expression returns a Proc of type :constant,
      #   otherwise return false.
      #
      # @param (see Matcher#matches?)
      # @return (see Matcher#matches?)
      def matches?(cell)
        CSVDecision::Constant.matches?(cell)
      end

      # (see Matcher#outs?)
      def outs?
        true
      end
    end
  end
end