# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the CSV file's header row. These methods are only required at table load time.
  # @api private
  module Header
    # Column types recognised in the header row.
    COLUMN_TYPE = %r{
      \A(?<type>in/text|in|out/text|out|guard|if|set/nil\?|set/blank\?|set|path)
      \s*:\s*(?<name>\S?.*)\z
    }xi

    # Regular expression string for a column name.
    # More lenient than a Ruby method name - note any spaces will have been replaced with
    # underscores.
    COLUMN_NAME = "\\w[\\w:/!?]*"

    # Regular expression for matching a column name.
    COLUMN_NAME_RE = Matchers.regexp(Header::COLUMN_NAME)
    private_constant :COLUMN_NAME_RE

    # Return true if column name is valid.
    #
    # @param column_name [String]
    # @return [Boolean]
    def self.column_name?(column_name)
      COLUMN_NAME_RE.match?(column_name)
    end

    # Check if the given row contains a recognisable header cell.
    #
    # @param row [Array<String>] Header row.
    # @return [Boolean] Return true if the row looks like a header.
    def self.row?(row)
      row.any? { |cell| COLUMN_TYPE.match?(cell) }
    end

    # Strip empty columns from all data rows.
    #
    # @param rows [Array<Array<String>>] Data rows.
    # @return [Array<Array<String>>] Data array after removing any empty columns
    #   and the header row.
    def self.strip_empty_columns(rows:)
      empty_cols = empty_columns?(row: rows.first)
      Data.strip_columns(data: rows, empty_columns: empty_cols) if empty_cols

      # Remove header row from the data array.
      rows.shift
    end

    # Parse the header row, and the defaults row if present.
    # @param table [CSVDecision::Table] Decision table being parsed.
    # @param matchers [Array<Matchers::Matcher>] Array of special cell matchers.
    # @return [CSVDecision::Columns] Table columns object.
    def self.parse(table:, matchers:)
      # Parse the header row
      table.columns = CSVDecision::Columns.new(table)

      # Parse the defaults row if present
      return table.columns if table.columns.defaults.blank?

      table.columns.defaults =
        Defaults.parse(columns: table.columns, matchers: matchers.outs, row: table.rows.shift)

      table.columns
    end

    # Build an array of all empty column indices.
    # @param row [Array]
    # @return [false, Array<Integer>]
    def self.empty_columns?(row:)
      result = []
      row&.each_with_index { |cell, index| result << index if cell == '' }

      result.empty? ? false : result
    end
    private_class_method :empty_columns?
  end
end