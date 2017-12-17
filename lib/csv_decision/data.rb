# frozen_string_literal: true

require 'csv'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  COMMENT_CHARACTER = '#'

  # Methods to load data from a file, CSV string or array of arrays
  module Data
    # Parse the input data which may either be a file path name, CSV string or
    # array of arrays. Strips out empty columns/rows and comment cells
    def self.to_array(data:, options: { force_encoding: 'UTF-8', ascii_only?: true })
      strip_rows(data: data_array(data), options: options)
    end

    # TODO: strip empty columns
    def self.strip_columns(_data:, _empty_cols:); end

    # Parse the input data which may either be a file path name, CSV string or
    # array of arrays
    def self.data_array(input)
      return CSV.read(input) if input.is_a?(Pathname)
      return input.deep_dup if input.is_a?(Array) && input[0].is_a?(Array)
      return CSV.parse(input) if input.is_a?(String)

      raise ArgumentError,
            "#{input.class} input invalid; " \
            'input must be a file path name, CSV string or array of arrays'
    end
    private_class_method :data_array

    def self.strip_rows(data:, options:)
      rows = []
      data.each do |row|
        row = strip_cells(row: row, options: options)
        rows << row if row.find { |cell| cell != '' }
      end
      rows
    end
    private_class_method :strip_rows

    # Strip cells of leading/trailing spaces; treat comments as an empty cell.
    # Non string values treated as empty cells.
    # Non-ascii strings treated as empty cells by default.
    def self.strip_cells(row:, options:)
      row.map! do |cell|
        next '' unless cell.is_a?(String)
        cell = options[:force_encoding] ? cell.force_encoding(options[:force_encoding]) : cell
        next '' if options[:ascii_only?] && !cell.ascii_only?
        next '' if cell.lstrip[0] == COMMENT_CHARACTER
        cell.strip
      end
    end
    private_class_method :strip_cells
  end
end