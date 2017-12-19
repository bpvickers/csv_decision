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
      @dictionary[:outs]
    end

    def path
      @dictionary[:outs]
    end

    def initialize(table)
      # The input and output columns, where the key is the row's array
      # column index. Note that input and output columns can be interspersed,
      # and need not have unique names.
      @dictionary = {
        ins: {},
        outs: {},
        # Path for the input hash - optional
        path: {},
        # Hash of columns that require defaults to be set
        defaults: {}
      }

      @dictionary =
        Header.parse_row(dictionary: @dictionary, row: table.rows.first)

      freeze
    end
  end
end