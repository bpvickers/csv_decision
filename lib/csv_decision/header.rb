# frozen_string_literal: true

require_relative 'parse_header'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the CSV file's header row
  class Header
    # Column header looks like IN :col_name or if:
    COLUMN_TYPE = %r{
      \A(?<type>in|out|in/text|out/text|set|path)
      \s*:\s*(?<name>\S?.*)\z
    }xi

    attr_reader :table
    attr_reader :ins
    attr_reader :outs
    attr_reader :defaults

    def initialize(table)
      @table = table

      # The input and output columns, where the key is the row's array
      # column index. Note that input and output columns can be interspersed,
      # and need not have unique names.
      @ins = {}
      @outs = {}

      # Path for the input hash - optional
      @path = {}

      # Hash of columns that require defaults to be set
      @defaults = {}

      row = table.rows.first
      parse(row) if row
    end

    def parse(row)
      index = 0
      while index < row.count
        cell = row[index]
        parse_cell(cell: cell, index: index) unless cell == ''

        index += 1
      end
    end

    def parse_cell(cell:, index:)
      column_type, column_name = ParseHeader.column?(cell: cell)

      type, text_only =
        parse_column_type(type: column_type, name: column_name, index: index)

      column_dictionary(type: type,
                        name: column_name,
                        index: index,
                        text_only: text_only)
    end

    # Returns the normalized column type, along with an indication if
    # the column is text only
    def parse_column_type(type:, name:, index:)
      case type
      # Header column that has a function for setting the value
      when :set
        @defaults[index] = { name: name, function: nil }
        # Treat set: as an in: column which may or may not be text-only.
        [:in, nil]

      when :'in/text'
        [:in, true]

      when :'out/text'
        [:in, true]

      # Column may turn out to be text-only, or not
      else
        [type, nil]
      end
    end

    # Returns the normalized column type, along with an indication if
    # the column is text only.
    def column_dictionary(type:, name:, index:, text_only:)
      entry = { name: name, text_only: text_only }

      case type
        # Header column that has a function for setting the value
      when :in
        @ins[index] = entry

      when :out
        @outs[index] = entry

      else
        raise "internal error - column type #{type} not recognised"
      end
    end
  end
end