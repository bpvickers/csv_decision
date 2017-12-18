# frozen_string_literal: true

require_relative 'parse_header'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the CSV file's header row
  class Header
    # Column header looks like IN :col_name or if:
    COLUMN_TYPE = %r{\A(?<type>in|out|in/text|out/text|set)\s*:\s*(?<name>\S?.*)\z}i

    attr_reader :table

    def initialize(table)
      @table = table

      row = table.rows.first
      process(row) if row
    end

    def process(row)
      index = 0
      while index < row.count
        cell = row[index]
        parse_cell(cell: cell, column: index) unless cell == ''

        index += 1
      end
    end

    def parse_cell(cell:, column:)
      column_type, columns_name = ParseHeader.column?(cell: cell)
    end
  end
end