# frozen_string_literal: true

require_relative 'table'
require_relative 'data'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the input data which may either be a path name, CSV string or array of arrays
  def self.parse(input, options: {})
    table = CSVDecision::Table.new
    Parse.data(table: table, input: input, options: options)

    table.freeze
  end

  # Parse the CSV file and create a new decision table object
  module Parse
    def self.data(table:, input:, options:)
      table.rows = Data.to_array(input)

      table
    end
  end
end