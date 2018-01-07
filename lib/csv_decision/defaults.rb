# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers.
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the default row beneath the header row if present
  # @api private
  module Defaults
    # Parse the defaults row that (optionally) appears just after the header row.
    # We have already determined that this row must be present.
    # @param columns [{Integer=>Dictionary::Entry}] Hash of header columns with defaults.
    # @param matchers [Array<Matchers>] Output cell special matchers.
    # @param row [Array<String>] Defaults row that appears just after the header row.
    # @raise [TableValidationError] Missing defaults row.
    def self.parse(columns:, matchers:, row:)
      raise TableValidationError, 'Missing defaults row' if row.nil?

      defaults = columns.defaults

      # Scan the default row for procs and constants
      scan_row = ScanRow.new.scan_columns(row: row, columns: defaults, matchers: matchers)

      parse_columns(defaults: defaults, columns: columns.dictionary, row: scan_row)
    end

    def self.parse_columns(defaults:, columns:, row:)
      defaults.each_pair do |col, entry|
        parse_cell(cell: row[col], columns: columns, entry: entry)
      end

      defaults
    end
    private_class_method :parse_columns

    def self.parse_cell(cell:, columns:, entry:)
      return entry.function = cell unless cell.is_a?(Matchers::Proc)

      entry.function = cell.function

      # Add any referenced input column symbols to the column name dictionary
      Parse.ins_cell_dictionary(columns: columns, cell: cell)
    end
    private_class_method :parse_cell
  end
end