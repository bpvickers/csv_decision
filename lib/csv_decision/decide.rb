# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Main module for searching the decision table looking for one or more matches
  # @api private
  module Decide
    # Match the table row against the input hash.
    #
    # @param row [Array] Table row.
    # @param input [Hash{Symbol=>Object}] Input hash data structure.
    # @param scan_row [ScanRow]
    # @return [Boolean] Returns true if a match, false otherwise.
    def self.matches?(row:, input:, scan_row:)
      match = scan_row.match_constants?(row: row, scan_cols: input[:scan_cols])
      return false unless match

      return true if scan_row.procs.empty?

      scan_row.match_procs?(row: row, input: input)
    end

    # Main method for making decisions.
    #
    # @param table [CSVDecision::Table] Decision table.
    # @param input [Hash] Input hash (keys may or may not be symbolized)
    # @param symbolize_keys [true, false] Set to false if keys are symbolized and it's
    #   OK to mutate the input hash. Otherwise a copy of the input hash is symbolized.
    # @return [Hash] Decision result.
    def self.decide(table:, input:, symbolize_keys:)
      # Parse and transform the hash supplied as input
      parsed_input = Input.parse(table: table, input: input, symbolize_keys: symbolize_keys)

      # The decision object collects the results of the search and
      # calculates the final result
      decision = Decision.new(table: table, input: parsed_input)

      # table_scan(table: table, input: parsed_input, decision: decision)
      decision.scan(table: table, input: parsed_input)
    end
  end
end