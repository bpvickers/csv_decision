# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  class Error < StandardError; end
  class CellValidationError < Error; end
  class FileError < Error; end

  # Builds a decision table from the input data - which may either be a file, CSV string
  # or array of arrays.
  #
  # @param input [Pathname, File, Array<Array<String>>, String] - input data
  # @param options [Hash] - options hash supplied by the user
  # @return [CSVDecision::Table] - resulting decision table
  def self.parse(data, options = {})
    Parse.table(input: data, options: Options.normalize(options))
  end

  # Parse the CSV file and create a new decision table object.
  # @param input [Pathname, File, Array<Array<String>>, String] - input data
  # @param options [Hash] - normalized options hash
  # @return [CSVDecision::Table] - resulting decision table
  module Parse
    def self.table(input:, options:)
      # Initialize the table object that this method will eventually return.
      table = CSVDecision::Table.new

      # In most cases the decision table will be loaded from a CSV file.
      table.file = input if Data.input_file?(input)

      # Parse input data into an array of arrays
      table.rows = Data.to_array(data: input)

      # Pick up any options specified in the CSV file before the header row.
      # These override any options passed as parameters to the parse method.
      table.options = Options.from_csv(table: table, attributes: options).freeze

      # Parse the header row
      table.columns = CSVDecision::Columns.new(table)

      parse_data(table: table, matchers: matchers(table.options).freeze)
    rescue CSVDecision::Error => exp
      raise exp unless table.file
      message = "error processing CSV file #{table.file}\n#{exp.inspect}"
      raise CSVDecision::FileError, message
    end

    def self.parse_data(table:, matchers:)
      index = 0
      while index < table.rows.count
        row = table.rows[index]

        # Build an array of column indexes requiring simple matches.
        # and a second array of columns requiring special matchers
        table.scan_rows[index] = Matchers.parse(columns: table.columns.ins,
                                                matchers: matchers,
                                                row: row)

        # parse_outputs(row, index)

        row.freeze
        table.scan_rows[index].freeze

        index += 1
      end

      table.columns.freeze

      table.freeze
    end
    private_class_method :parse_data

    def self.matchers(options)
      options[:matchers].collect { |klass| klass.new(options) }
    end
    private_class_method :matchers
  end
end