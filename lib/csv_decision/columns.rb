# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Dictionary of all this table's columns - inputs, outputs etc.
  class Columns
    # Value object used for column dictionary entries
    Entry = Struct.new(:name, :text_only)

    # Value object used for columns with defaults
    Default = Struct.new(:name, :function, :default_if)

    # Dictionary of all data columns.
    # # Note that the key of each hash is the header cell's array column index.
    # Note that input and output columns can be interspersed and need not have unique names.
    class Dictionary
      attr_accessor :ins
      attr_accessor :outs
      attr_accessor :path
      attr_accessor :defaults

      def initialize
        @ins = {}
        @outs = {}

        # Path for the input hash - optional
        @path = {}
        # Hash of columns that require defaults to be set
        @defaults = {}
      end
    end

    # Dictionary of all data columns
    attr_reader :dictionary

    # Input columns
    def ins
      @dictionary.ins
    end

    # Output columns
    def outs
      @dictionary.outs
    end

    # Input columns with defaults specified
    def defaults
      @dictionary.defaults
    end

    # Input hash path (planned feature)
    def path
      @dictionary.path
    end

    def initialize(table)
      # If a column does not have a valid header cell, then it's empty of data.
      # Return the stripped header row, removing it from the data array.
      row = Header.strip_empty_columns(rows: table.rows)

      # Build a dictionary of all valid data columns from the header row.
      @dictionary = Header.dictionary(row: row) if row

      freeze
    end
  end
end