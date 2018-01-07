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
      ins_column_dictionary(columns: table.columns.dictionary, row: row)

      row
    end
    private_class_method :parse_row_ins

    def self.parse_row_outs(table:, matchers:, row:, index:)
      # Parse the output cells for this row
      row, table.outs_rows[index] = matchers.parse_outs(columns: table.columns.outs, row: row)

      outs_column_dictionary(columns: table.columns, row: row)

      row
    end
    private_class_method :parse_row_outs

    def self.outs_column_dictionary(columns:, row:)
      row.each_with_index do |cell, index|
        outs_check_cell(columns: columns, cell: cell, index: index)
      end
    end
    private_class_method :outs_column_dictionary

    def self.outs_check_cell(columns:, cell:, index:)
      return unless cell.is_a?(Matchers::Proc)
      return if cell.symbols.nil?

      check_outs_symbols(columns: columns, cell: cell, index: index)
    end
    private_class_method :outs_check_cell

    def self.check_outs_symbols(columns:, cell:, index:)
      Array(cell.symbols).each do |symbol|
        check_outs_symbol(columns: columns, symbol: symbol, index: index)
      end
    end
    private_class_method :check_outs_symbols

    def self.check_outs_symbol(columns:, symbol:, index:)
      in_out = columns.dictionary[symbol]

      # If its an input column symbol then we're good.
      return if ins_symbol?(columns: columns, symbol: symbol, in_out: in_out)

      # Check if this output symbol reference is on or after this cell's column
      invalid_out_ref?(columns, index, in_out)
    end
    private_class_method :check_outs_symbol

    # If the symbol exists either as an input or does not exist then we're good.
    def self.ins_symbol?(columns:, symbol:, in_out:)
      return true if in_out == :in

      # It must an input symbol, as all the output symbols have been parsed.
      return columns.dictionary[symbol] = :in if in_out.nil?

      false
    end
    private_class_method :ins_symbol?

    def self.invalid_out_ref?(columns, index, in_out)
      return false if in_out < index

      that_column = if in_out == index
                      'reference to itself'
                    else
                      "an out of order reference to output column '#{columns.outs[in_out].name}'"
                    end
      raise CellValidationError,
            "output column '#{columns.outs[index].name}' makes #{that_column}"
    end

    def self.ins_column_dictionary(columns:, row:)
      row.each { |cell| ins_cell_dictionary(columns: columns, cell: cell) }
    end
    private_class_method :ins_column_dictionary

    def self.ins_cell_dictionary(columns:, cell:)
      return unless cell.is_a?(Matchers::Proc)
      return if cell.symbols.nil?

      add_ins_symbols(columns: columns, cell: cell)
    end
    private_class_method :ins_cell_dictionary

    def self.add_ins_symbols(columns:, cell:)
      Array(cell.symbols).each do |symbol|
        Dictionary.add_name(columns: columns, name: symbol)
      end
    end
    private_class_method :add_ins_symbols

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