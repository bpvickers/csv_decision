# frozen_string_literal: true

require 'values'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  class Proc < Value.new(:type, :function); end

  # Methods to assign a matcher to data cells
  module Matchers
    NEGATE = '!'

    # All regular expressions used for matching are anchored
    def self.regexp(value)
      Regexp.new("\\A(#{value})\\z").freeze
    end

    NUMERIC = '[-+]?\d*(?<decimal>\.?)\d+'
    NUMERIC_RE = regexp(NUMERIC)

    def self.numeric(value)
      return value if value.is_a?(Integer) || value.is_a?(BigDecimal)
      return unless value.is_a?(String)

      to_numeric(value)
    end

    def self.to_numeric(value)
      return unless (match = NUMERIC_RE.match(value))
      return value.to_i if match['decimal'] == ''
      BigDecimal.new(value.chomp('.'))
    end

    def self.parse(table:, row:)
      # Build an array of column indexes requiring simple constant matches,
      # and a second array of columns requiring special matchers.
      scan_row = [[], []]

      table.columns.ins.each_pair do |col, column|
        # Empty cell matches everything, and so never needs to be scanned
        next if row[col] == ''

        # If the column is text only then no special matchers need be invoked
        next scan_row.first << col if column[:text_only]

        # Scan the cell against all the matchers
        proc = scan(matchers: table.matchers, cell: row[col])

        # Did we get a proc or a simple constant?
        next scan_row.first << col unless proc

        # Replace the cell's string with the proc
        row[col] = proc
        scan_row.last << col
      end

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