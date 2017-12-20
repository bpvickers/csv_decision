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
      decision = Decision.new(table: table, input: parsed_input)

      table_scan(table: table, input: parsed_input, decision: decision)
    end

    def self.table_scan(table:, input:, decision:)
      first_match = table.options[:first_match]

      scan_rows = table.scan_rows

      table.each do |row, index|
        next unless matches?(row: row, input: input, scan_row: scan_rows[index])

        decision.add(row)

        return decision if first_match
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
        next unless scan_cols.key?(col)
        return false unless row[col] == scan_cols[col]
      end

      true
    end

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

    def self.eval_matcher(proc:, value:, hash:)
      # A symbol expression just needs to be pass the input hash
      return proc.function[hash] if proc.type == :expression

      # All other procs can take one or two args
      proc.function.arity == 1 ? proc.function[value] : proc.function[value, hash]
    end
  end
end