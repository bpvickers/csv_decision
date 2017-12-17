# frozen_string_literal: true

require_relative 'table'
require_relative 'data'
require_relative 'options'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the input data which may either be a path name, CSV string or array of arrays
  def self.parse(input, options: {})
    # Parse and normalize user supplied options
    options = Options.new(options)

    # Initialize the table object
    table = CSVDecision::Table.new(options)

    # Parse input data, which may include overriding options specified in a CSV file
    table = Parse.data(table: table, input: input, options: options)

    table.freeze
  end

  # Parse the CSV file and create a new decision table object
  module Parse
    def self.data(table:, input:, options:)
      table.rows = Data.to_array(data: input, options: options)
      table.file = input if input.is_a?(Pathname)

      table
    end
  end
end