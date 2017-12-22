# frozen_string_literal: true

require 'values'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  class Proc < Value.new(:type, :function); end

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
    # @param columns []
    def self.parse(columns:, matchers:, row:)
      # Build an array of column indexes requiring simple constant matches,
      # and a second array of columns requiring special matchers.
      scan_row = [[], []]

      columns.each_pair do |col, column|
        # Empty cell matches everything, and so never needs to be scanned
        next if row[col] == ''

        # If the column is text only then no special matchers need be invoked
        next scan_row.first << col if column.text_only

        # Scan the cell against all the matchers
        proc = scan(matchers: matchers, cell: row[col])

        # Did we get a proc or a simple constant?
        next scan_row.first << col unless proc

        # Replace the cell's string value with the proc
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