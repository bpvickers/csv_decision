# frozen_string_literal: true

require 'values'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  class Proc < Value.new(:type, :function); end

  # Methods to assign a matcher to data cells
  module Matchers
    # All regular expressions used for matching are anchored
    def self.regexp(value)
      Regexp.new("\\A(#{value})\\z").freeze
    end
  end
end