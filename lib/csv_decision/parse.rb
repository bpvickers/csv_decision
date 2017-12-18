# frozen_string_literal: true

require_relative 'table'
require_relative 'parse_header'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  class Error < StandardError; end
  class CellValidationError < Error; end
  class FileError < Error; end

  # Parse the input data which may either be a path name, CSV string or array of arrays
  def self.parse(input, options = {})
    # Parse and normalize user supplied options
    options = Options.new(options)

    # Parse input data, which may include overriding options specified in a CSV file
    table = Parse.data(table: Table.new, input: input, options: options)

    options = options.from_csv(table)

    table.header = ParseHeader.parse(table: table, options: options)

    # Set to the options hash
    table.options = options.attributes.freeze

    Parse.data_rows(table)

  rescue CSVDecision::Error => exp
    raise exp unless table.file
    message = "error processing CSV file #{table.file}\n#{exp.inspect}"
    raise CSVDecision::FileError, message
  end

  # Parse the CSV file and create a new decision table object
  module Parse
    def self.data(table:, input:, options:)
      table.file = input if Data.input_file?(input)
      table.rows = Data.to_array(data: input, options: options.attributes)

      table
    end

    def self.data_rows(table)
      table.freeze
    end
  end
end