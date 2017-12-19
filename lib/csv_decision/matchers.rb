# frozen_string_literal: true

require 'values'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  class Proc < Value.new(:type, :function); end

  # Methods to assign a matcher to data cells
  module Matchers
    # All regular expressions used for matching are anchored
    def self.regexp(value)
      Regexp.new("\\A(#{value})\\z").freeze
    end

    def self.parse(table:, row:)
      # Build an array of column indexes requiring simple matches.
      # and second array of columns requiring special matchers
      scan_row = [[], []]

      table.columns.ins.each_pair do |col, column|
        # Empty cell matches everything, and so never needs to be scanned
        next if row[col] == ''

        # If the column is text only then no special matchers need be invoked
        # if column[:text_only]
        #   scan_row.first << col
        next scan_row.first << col if column[:text_only]

        # Scan the cell against all the matchers
        proc = scan(matchers: table.matchers, cell: row[col])

        # Did we get a proc or a simple constant?
        next scan_row.first << col if proc == :constant

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
      :constant
    end
  end
end