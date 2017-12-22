# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Dictionary of all this table's columns - inputs, outputs etc.
  class Columns
    class Entry < Value.new(:name, :text_only); end

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
      # If a column does not have a valid header cell, then it's empty of data.
      # Return the stripped header row, removing it from the data array.
      row = Header.strip_empty_columns(rows: table.rows)

      # Build a dictionary of all valid data columns.
      @dictionary = Header.dictionary(row: row)

      freeze
    end
  end
end