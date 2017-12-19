# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Main method for seraching the decision table looking for one or more matches
  module Decide
    def self.decide(table:, input:, symbolize_keys: false)
      # Parse and transform the hash supplied as input
      parsed_input = Input.parse(table: table, input: input, symbolize_keys: symbolize_keys)

      # The decision object collects the results of the search and calculates the final result
      # decision = Decision.new(table: table, input: parsed_input)
    end
  end
end