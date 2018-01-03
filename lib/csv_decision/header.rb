# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the CSV file's header row. These methods are only required at table load time.
  # @api private
  module Header
    # TODO: implement all column types
    # COLUMN_TYPE = %r{
    #   \A(?<type>in|out|in/text|out/text|set|set/nil|set/blank|path|guard|if)
    #   \s*:\s*(?<name>\S?.*)\z
    # }xi

    # Column types recognised in the header row.
    COLUMN_TYPE = %r{
      \A(?<type>in|out|in/text|out/text|guard|if)
      \s*:\s*(?<name>\S?.*)\z
    }xi

    # Regular expression string for a column name.
    # More lenient than a Ruby method name - note any spaces will have been replaced with
    # underscores.
    COLUMN_NAME = "\\w[\\w:/!?]*"
    COLUMN_NAME_RE = Matchers.regexp(Header::COLUMN_NAME)

    # Check if the given row contains a recognisable header cell.
    #
    # @param row [Array<String>] Header row.
    # @return [Boolean] Return true if the row looks like a header.
    def self.row?(row)
      row.find { |cell| cell.match(COLUMN_TYPE) }
    end

    # Strip empty columns from all data rows.
    #
    # @param rows [Array<Array<String>>] Data rows.
    # @return [Array<Array<String>>] Data array after removing any empty columns and the
    #   header row.
    def self.strip_empty_columns(rows:)
      empty_cols = empty_columns?(row: rows.first)
      Data.strip_columns(data: rows, empty_columns: empty_cols) if empty_cols

      # Remove header row from the data array.
      rows.shift
    end

    # Array of all empty column indices.
    def self.empty_columns?(row:)
      result = []
      row&.each_with_index { |cell, index| result << index if cell == '' }

      result.empty? ? false : result
    end
    private_class_method :empty_columns?
  end
end