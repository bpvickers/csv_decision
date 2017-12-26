# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers.
# See LICENSE and README.md for details.
module CSVDecision
  # All CSVDecision specific errors
  class Error < StandardError; end

  # Error validating a cell when parsing input table data.
  class CellValidationError < Error; end

  # Table parsing error message enhanced to include the file being processed
  class FileError < Error; end

  # Builds a decision table from the input data - which may either be a file, CSV string
  # or an array of arrays.
  #
  # @example Simple Example
  #   If you have cloned the gem's git repo, then you can run:
  #   table = CSVDecision.parse(Pathname('spec/data/valid/simple_example.csv')) #=> CSVDecision::Table
  #   table.decide(topic: 'finance', region: 'Europe') #=> team_member: 'Donald'
  #
  # @param data [Pathname, File, Array<Array<String>>, String] input data given as
  #   a CSV file, array of arrays or CSV string.
  # @param options [Hash] Options hash supplied by the user.
  #
  # @option options [Boolean] :first_match Stop scanning after find the first row match.
  # @option options [Boolean] :regexp_implicit Make regular expressions implicit rather than requiring the
  #   comparator =~. (Use with care.)
  # @option options [Boolean] :text_only All cells treated as simple strings by turning off all special matchers.
  # @option options [Array<Matchers::Matcher>] :matchers May be used to control the inclusion and ordering of
  #   special matchers. (Advanced feature, use with care.)
  #
  # @return [CSVDecision::Table] Resulting decision table.
  #
  # @raise [CSVDecision::CellValidationError] Table parsing cell validation error.
  # @raise [CSVDecision::FileError] Table parsing error for a named CSV file.
  #
  def self.parse(data, options = {})
    Parse.table(data: data, options: Options.normalize(options))
  end

  # Methods to parse the decision table and return CSVDecision::Table object.
  module Parse
    # Parse the CSV file or input data and create a new decision table object.
    #
    # @param (see CSVDecision.parse)
    # @return (see CSVDecision.parse)
    def self.table(data:, options:)
      table = CSVDecision::Table.new

      # In most cases the decision table will be loaded from a CSV file.
      table.file = data if Data.input_file?(data)

      parse_table(table: table, input: data, options: options)

      table.freeze
    rescue CSVDecision::Error => exp
      raise_error(file: table.file, exception: exp)
    end

    def self.raise_error(file:, exception:)
      raise exception unless file

      raise CSVDecision::FileError,
            "error processing CSV file #{file}\n#{exception.inspect}"
    end
    private_class_method :raise_error

    def self.parse_table(table:, input:, options:)
      # Parse input data into an array of arrays
      table.rows = Data.to_array(data: input)

      # Pick up any options specified in the CSV file before the header row.
      # These override any options passed as parameters to the parse method.
      table.options = Options.from_csv(rows: table.rows, options: options).freeze

      # Parse the header row
      table.columns = CSVDecision::Columns.new(table)

      parse_data(table: table, matchers: Matchers.new(options))
    end
    private_class_method :parse_table

    def self.parse_data(table:, matchers:)
      table.rows.each_with_index do |row, index|
        row, table.scan_rows[index] = matchers.parse_ins(columns: table.columns.ins, row: row)
        row, table.outs_rows[index] = matchers.parse_outs(columns: table.columns.outs, row: row)

        row.freeze
      end

      table.columns.freeze
    end
    private_class_method :parse_data
  end
end