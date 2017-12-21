# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Dictionary of all this table's columns - inputs, outputs etc.
  class Columns
    attr_reader :dictionary

    def ins
      @dictionary[:ins]
    end

    def outs
      @dictionary[:outs]
    end

    def defaults
      @dictionary[:defaults]
    end

    def path
      @dictionary[:path]
    end

    def initialize(table)
      # If a column does not have a valid header cell, then it is empty of data
      Header.strip_empty_columns(table: table)

      # Build a dictionary of all valid data columns and remove the header row,
      # leaving just the non-empty data rows and columns.
      @dictionary = Header.dictionary(row: Header.shift(table))

      freeze
    end
  end
end