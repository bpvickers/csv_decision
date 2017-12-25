# frozen_string_literal: true

require 'values'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Value object for a cell proc
  Proc = Value.new(:type, :function)

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
    NUMERIC = '[-+]?\d*(?<decimal>\.?)\d*'
    NUMERIC_RE = regexp(NUMERIC)

    def self.numeric?(value)
      value.is_a?(Integer) || value.is_a?(BigDecimal)
    end

    # def self.decimal?(value)
    #   return match if value.is_a?(String) && (match = NUMERIC_RE.match(value))
    #   return value if numeric?(value)
    #
    #   false
    # end
    #
    # def self.to_decimal(value)
    #   return value if numeric?(value)
    #
    #   return false unless value.is_a?(String) && (match = NUMERIC_RE.match(value))
    #   coerce_decimal(match, value)
    # end

    # Validate a numeric value and convert it to an Integer or BigDecimal if a valid string.
    #
    # @param value [nil, String, Integer, BigDecimal]
    # @return [nil, Integer, BigDecimal]
    def self.numeric(value)
      return value if numeric?(value)
      return unless value.is_a?(String)

      to_numeric(value)
    end

    # Validate a numeric string and convert it to an Integer or BigDecimal.
    #
    # @param value [String]
    # @return [nil, Integer, BigDecimal]
    def self.to_numeric(value)
      return unless (match = NUMERIC_RE.match(value))
      coerce_numeric(match, value)
    end

    def self.coerce_numeric(match, value)
      return value.to_i if match['decimal'] == ''
      BigDecimal(value.chomp('.'))
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

    # @abstract Subclass and override {#matches?} to implement
    #   a custom Matcher class.
    class Matcher
      def initialize(_options = nil); end

      def matches?(_cell); end
    end
  end
end