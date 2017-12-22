# frozen_string_literal: true

require 'values'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Data row object indicating which columns are constants versus procs.
  class ScanRow
    attr_accessor :constants
    attr_accessor :procs

    def initialize
      @constants = []
      @procs = []
    end

    def scan_columns(columns:, matchers:, row:)
      columns.each_pair do |col, column|
        # Empty cell matches everything, and so never needs to be scanned
        next if row[col] == ''

        # If the column is text only then no special matchers need be invoked
        next constants << col if column.text_only

        # Need to scan the cell against all matchers
        row[col] = scan_cell(col: col, matchers: matchers, cell: row[col])
      end
    end

    def match_constants?(row:, scan_cols:)
      constants.each do |col|
        value = scan_cols.fetch(col, [])
        # This only happens if the column is indexed
        next if value == []
        return false unless row[col] == value
      end

      true
    end

    def match_procs?(row:, input:)
      hash = input[:hash]
      scan_cols = input[:scan_cols]

      procs.each do |col|
        match = Decide.eval_matcher(proc: row[col], value: scan_cols[col], hash: hash)
        return false unless match
      end

      true
    end

    private

    def scan_cell(col:, matchers:, cell:)
      # Scan the cell against all the matchers
      proc = Matchers.scan(matchers: matchers, cell: cell)

      if proc
        procs << col
        return proc
      end

      constants << col
      cell
    end
  end
end