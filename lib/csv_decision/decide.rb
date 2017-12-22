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

      table_scan(table: table, input: parsed_input, decision: decision)
    end

    def self.table_scan(table:, input:, decision:)
      scan_rows = table.scan_rows

      table.each do |row, index|
        next unless matches?(row: row, input: input, scan_row: scan_rows[index])

        done = decision.add(row)

        return decision if done
      end

      decision
    end
    private_class_method :table_scan

    def self.matches?(row:, input:, scan_row:)
      match = match_constants?(row: row,
                               scan_cols: input[:scan_cols],
                               constant_cells: scan_row.first)
      return false unless match

      return true if (proc_cells = scan_row.last).empty?

      match_procs?(row: row, input: input, proc_cells: proc_cells)
    end
    private_class_method :matches?

    def self.match_constants?(row:, scan_cols:, constant_cells:)
      constant_cells.each do |col|
        value = scan_cols.fetch(col, [])
        # This only happens if the column is indexed
        next if value == []
        return false unless row[col] == value
      end

      true
    end
    private_class_method :match_constants?

    def self.match_procs?(row:, input:, proc_cells:)
      hash = input[:hash]
      scan_cols = input[:scan_cols]

      proc_cells.each do |col|
        return false unless eval_matcher(proc: row[col],
                                         value: scan_cols[col],
                                         hash: hash)
      end

      true
    end
    private_class_method :match_procs?

    def self.eval_matcher(proc:, value:, hash:)
      function = proc.function

      # A symbol expression just needs to be passed the input hash
      return function[hash] if proc.type == :expression

      # All other procs can take one or two args
      function.arity == 1 ? function[value] : function[value, hash]
    end
    private_class_method :eval_matcher
  end
end