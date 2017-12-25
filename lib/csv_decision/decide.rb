# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Main module for searching the decision table looking for one or more matches
  module Decide
    # Main method for making decisions.
    #
    # @param table [CSVDecision::Table]
    # @param input [Hash] - input hash (keys may or may not be symbolized)
    # @param symbolize_keys [true, false] - set to true if keys are symbolized and it's
    #   OK to mutate the input hash. Otherwise a copy of the input hash is symbolized.
    # @return [Hash]
    def self.decide(table:, input:, symbolize_keys:)
      # Parse and transform the hash supplied as input
      parsed_input = Input.parse(table: table, input: input, symbolize_keys: symbolize_keys)

      # The decision object collects the results of the search and
      # calculates the final result
      decision = Decision.new(table: table, input: parsed_input)

      # table_scan(table: table, input: parsed_input, decision: decision)
      decision.scan(table: table, input: parsed_input)
    end

    def self.matches?(row:, input:, scan_row:)
      match = scan_row.match_constants?(row: row, scan_cols: input[:scan_cols])
      return false unless match

      return true if scan_row.procs.empty?

      scan_row.match_procs?(row: row, input: input)
    end

    def self.eval_matcher(proc:, value:, hash:)
      function = proc.function

      # A symbol guard expression just needs to be passed the input hash
      return function[hash] if proc.type == :expression

      # All other procs can take one or two args
      function.arity == 1 ? function[value] : function[value, hash]
    end
  end
end