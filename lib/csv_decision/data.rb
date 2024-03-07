# frozen_string_literal: true

require 'csv'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details..
module CSVDecision
  # All cells starting with this character are comments, and treated as a blank cell.
  COMMENT_CHARACTER = '#'
  private_constant :COMMENT_CHARACTER

  # Methods to load data from a file, CSV string or an array of arrays.
  # @api private
  module Data
    # Options passed to CSV.parse and CSV.read.
    CSV_OPTIONS = { encoding: 'UTF-8', skip_blanks: true }.freeze
    private_constant :CSV_OPTIONS

    # Parse the input data which may either be a file path name, CSV string or
    # array of arrays. Strips out empty columns/rows and comment cells.
    #
    # @param data (see Parse.parse)
    # @return [Array<Array<String>>] Data array stripped of empty rows.
    def self.to_array(data:)
      strip_rows(data: data_array(data))
    end

    # If the input is a file name return true, otherwise false.
    #
    # @param data (see Parse.parse)
    # @return [Boolean] Set to true if the input data is passed as a File or Pathname.
    def self.input_file?(data)
      data.is_a?(Pathname) || data.is_a?(File)
    end

    # Strip the empty columns from the input data rows.
    #
    # @param data (see Parse.parse)
    # @param empty_columns [Array<Index>]
    # @return [Array<Array<String>>] Data array stripped of empty columns.
    def self.strip_columns(data:, empty_columns:)
      # Adjust column indices as we delete columns the rest shift to the left by 1
      empty_columns.map!.with_index { |col, index| col - index }

      # Delete all empty columns from the array of arrays
      empty_columns.each { |col| data.each_index { |row| data[row].delete_at(col) } }
    end

    # Parse the input data which may either be a file path name, CSV string or
    # array of arrays
    def self.data_array(input)
      return CSV.read(input, **CSV_OPTIONS) if input_file?(input)
      return input.deep_dup if input.is_a?(Array) && input[0].is_a?(Array)
      return CSV.parse(input, **CSV_OPTIONS) if input.is_a?(String)

      raise ArgumentError,
            "#{input.class} input invalid; " \
            'input must be a file path name, CSV string or array of arrays'
    end
    private_class_method :data_array

    def self.strip_rows(data:)
      rows = []
      data.each do |row|
        row = strip_cells(row: row)
        rows << row if row.find { |cell| cell != '' }
      end
      rows
    end
    private_class_method :strip_rows

    # Strip cells of leading/trailing spaces; treat comments as an empty cell.
    # Non string values treated as empty cells.
    # Non-ascii strings treated as empty cells by default.
    def self.strip_cells(row:)
      row.map! { |cell| strip_cell(cell) }
    end
    private_class_method :strip_cells

    def self.strip_cell(cell)
      return '' unless cell.is_a?(String)
      cell = cell.force_encoding('UTF-8')
      return '' unless cell.ascii_only?
      return '' if cell.lstrip[0] == COMMENT_CHARACTER

      cell.strip
    end
    private_class_method :strip_cell
  end
end
