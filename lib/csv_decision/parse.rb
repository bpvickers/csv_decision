# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers.
# See LICENSE and README.md for details.
module CSVDecision
  # All CSVDecision specific errors
  class Error < StandardError; end

  # Error validating a cell when parsing input table data.
  class TableValidationError < Error; end

  # Error validating a cell when parsing input table cell data.
  class CellValidationError < Error; end

  # Table parsing error message enhanced to include the file being processed.
  class FileError < Error; end

  # Builds a decision table from the input data - which may either be a file, CSV string
  # or an array of arrays.
  #
  # @example Simple Example
  #   If you have cloned the gem's git repo, then you can run:
  #   table = CSVDecision.parse(Pathname('spec/data/valid/simple_example.csv'))
  #     #=> CSVDecision::Table
  #   table.decide(topic: 'finance', region: 'Europe') #=> team_member: 'Donald'
  #
  # @param data [Pathname, File, Array<Array<String>>, String] input data given as
  #   a CSV file, array of arrays or CSV string.
  # @param options [Hash] Options hash supplied by the user.
  #
  # @option options [Boolean] :first_match Stop scanning after finding the first row match.
  # @option options [Boolean] :regexp_implicit Make regular expressions implicit rather than
  #   requiring the comparator =~. (Use with care.)
  # @option options [Boolean] :text_only All cells treated as simple strings by turning off all
  #   special matchers.
  # @option options [Array<Matchers::Matcher>] :matchers May be used to control the inclusion and
  #   ordering of special matchers. (Advanced feature, use with care.)
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
  # @api private
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

      # The table object is now immutable.
      table.columns.freeze
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
      # Parse input data into an array of arrays.
      table.rows = Data.to_array(data: input)

      # Pick up any options specified in the CSV file before the header row.
      # These override any options passed as parameters to the parse method.
      table.options = Options.from_csv(rows: table.rows, options: options).freeze

      # Parse table header and data rows with special cell matchers.
      parse_with_matchers(table: table, matchers: CSVDecision::Matchers.new(options))

      # Build the index if one is indicated
      Index.build(table: table)
    end
    private_class_method :parse_table

    def self.parse_with_matchers(table:, matchers:)
      # Parse the header row
      table.columns = Header.parse(table: table, matchers: matchers)

      # Parse the table's the data rows.
      parse_data(table: table, matchers: matchers)
    end
    private_class_method :parse_with_matchers

    def self.parse_data(table:, matchers:)
      table.rows.each_with_index do |row, index|
        # Mutate the row if we find anything other than a simple string constant in its
        # data cells.
        row = parse_row(table: table, matchers: matchers, row: row, index: index)

        # Does the row have any output functions?
        outs_functions(table: table, index: index)

        # No more mutations required for this row.
        row.freeze
      end
    end
    private_class_method :parse_data

    def self.parse_row(table:, matchers:, row:, index:)
      # Parse the input cells for this row
      row = parse_row_ins(table: table, matchers: matchers, row: row, index: index)

      # Parse the output cells for this row
      parse_row_outs(table: table, matchers: matchers, row: row, index: index)
    end
    private_class_method :parse_row

    def self.parse_row_ins(table:, matchers:, row:, index:)
      # Parse the input cells for this row
      row, table.scan_rows[index] = matchers.parse_ins(columns: table.columns.ins, row: row)

      # Add any symbol references made by input cell procs to the column dictionary
      Columns.ins_dictionary(columns: table.columns.dictionary, row: row)

      row
    end
    private_class_method :parse_row_ins

    def self.parse_row_outs(table:, matchers:, row:, index:)
      # Parse the output cells for this row
      row, table.outs_rows[index] = matchers.parse_outs(columns: table.columns.outs, row: row)

      Columns.outs_dictionary(columns: table.columns, row: row)

      row
    end
    private_class_method :parse_row_outs

    def self.outs_functions(table:, index:)
      return if table.outs_rows[index].procs.empty?

      # Set this flag as the table has output functions
      table.outs_functions = true

      # Update the output columns that contain functions needing evaluation.
      table.outs_rows[index].procs.each { |col| table.columns.outs[col].eval = true }
    end
    private_class_method :outs_functions
  end
end