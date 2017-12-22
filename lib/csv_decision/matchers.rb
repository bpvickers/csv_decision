# frozen_string_literal: true

require 'values'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Value object for a cell proc
  Proc = Value.new(:type, :function)

  # Value object for a data row indicating which columns are constants versus procs.
  # ScanRow = Struct.new(:constants, :procs) do
  #   def scan_columns(columns:, matchers:, row:)
  #     columns.each_pair do |col, column|
  #       # Empty cell matches everything, and so never needs to be scanned
  #       next if row[col] == ''
  #
  #       # If the column is text only then no special matchers need be invoked
  #       next constants << col if column.text_only
  #
  #       # Need to scan the cell against all matchers
  #       row[col] = scan_cell(col: col, matchers: matchers, cell: row[col])
  #     end
  #   end
  #
  #   def match_constants?(row:, scan_cols:)
  #     constants.each do |col|
  #       value = scan_cols.fetch(col, [])
  #       # This only happens if the column is indexed
  #       next if value == []
  #       return false unless row[col] == value
  #     end
  #
  #     true
  #   end
  #
  #   def match_procs?(row:, input:)
  #     hash = input[:hash]
  #     scan_cols = input[:scan_cols]
  #
  #     procs.each do |col|
  #       return false unless Decide.eval_matcher(proc: row[col],
  #                                               value: scan_cols[col],
  #                                               hash: hash)
  #     end
  #
  #     true
  #   end
  #
  #   private
  #
  #   def scan_cell(col:, matchers:, cell:)
  #     # Scan the cell against all the matchers
  #     proc = Matchers.scan(matchers: matchers, cell: cell)
  #
  #     if proc
  #       procs << col
  #       return proc
  #     end
  #
  #     constants << col
  #     cell
  #   end
  # end

  # Methods to assign a matcher to data cells
  module Matchers
    # Negation sign for ranges and functions
    NEGATE = '!'

    # All regular expressions used for matching are anchored
    #
    # @param value [String]
    # @return [Regexp]
    def self.regexp(value)
      Regexp.new("\\A(#{value})\\z").freeze
    end

    # Regular expression used to recognise a numeric string with or without a decimal point.
    NUMERIC = '[-+]?\d*(?<decimal>\.?)\d+'
    NUMERIC_RE = regexp(NUMERIC)

    # Validate a numeric value and convert it to an Integer or BigDecimal if a valid string.
    #
    # @param value [nil, String, Integer, BigDecimal]
    # @return [nil, Integer, BigDecimal]
    def self.numeric(value)
      return value if value.is_a?(Integer) || value.is_a?(BigDecimal)
      return unless value.is_a?(String)

      to_numeric(value)
    end

    # Validate a numeric string and convert it to an Integer or BigDecimal.
    #
    # @param value [String]
    # @return [nil, Integer, BigDecimal]
    def self.to_numeric(value)
      return unless (match = NUMERIC_RE.match(value))
      return value.to_i if match['decimal'] == ''
      BigDecimal.new(value.chomp('.'))
    end

    # Parse the supplied input columns for the row supplied using an array of matchers.
    #
    # @param columns [Hash] - Input columns hash
    # @param matchers [Array]
    # @param row [Array]
    def self.parse(columns:, matchers:, row:)
      # Build an array of column indexes requiring simple constant matches,
      # and a second array of columns requiring special matchers.
      scan_row = ScanRow.new

      # scan_columns(columns: columns, matchers: matchers, row: row, scan_row: scan_row)
      scan_row.scan_columns(columns: columns, matchers: matchers, row: row)

      scan_row
    end

    def self.scan(matchers:, cell:)
      matchers.each do |matcher|
        proc = matcher.matches?(cell)
        return proc if proc
      end

      # Must be a simple constant
      false
    end
  end
end