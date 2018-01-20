# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers.
# See LICENSE and README.md for details.
module CSVDecision
  # Build an index for a decision table with one or more input columns
  # designated as keys
  # @api private
  class Index
    # Build the index on the designated number of input columns.
    #
    # @param table [CSVDecision::Table] Decision table being indexed.
    # @return [CSVDecision::Index] The built index.
    def self.build(table:)
      # Do we even have an index?
      key_cols = index_columns(columns: table.columns.ins)
      return if key_cols.empty?

      table.index = Index.new(table: table, columns: key_cols)

      # Indexed columns do not need to be scanned
      trim_scan_rows(scan_rows: table.scan_rows, index_columns: table.index.columns)

      table
    end

    # @param current_value [Integer, Array] Current index key value.
    # @param index [Integer] Array row index to be included in the table index entry.
    # @return [Integer, Array] New index key value.
    def self.value(current_value, index)
      return integer_value(current_value, index) if current_value.is_a?(Integer)

      array_value(current_value, index)

      current_value
    end

    def self.trim_scan_rows(scan_rows:, index_columns:)
      scan_rows.each { |scan_row| scan_row.constants = scan_row.constants - index_columns }
    end
    private_class_method :trim_scan_rows

    def self.index_columns(columns:)
      key_cols = []
      columns.each_pair { |col, column| key_cols << col if column.indexed }

      key_cols
    end
    private_class_method :index_columns

    # Current value is a row index integer
    def self.integer_value(current_value, index)
      # Is the new row index contiguous with the last start row/end row range?
      current_value + 1 == index ? [[current_value, index]] : [current_value, index]
    end
    private_class_method :integer_value

    # Current value is an array of row indexes
    def self.array_value(current_value, index)
      start_row, end_row = current_value.last

      end_row = start_row if end_row.nil?

      # Is the new row index contiguous with the last start row/end row range?
      end_row + 1 == index ? current_value[-1] = [start_row, index] : current_value << index
    end
    private_class_method :array_value

    # @return [Hash] The index hash mapping in input values to one or more data array row indexes.
    attr_reader :hash

    # @return [Array<Integer>] Array of column indices
    attr_reader :columns

    # @param table [CSVDecision::Table] Decision table.
    # @param columns [Array<Index>] Array of column indexes to be indexed.
    def initialize(table:, columns:)
      @columns = columns
      @hash = {}

      build(table)

      freeze
    end

    private

    def build(table)
      table.each do |row, index|
        key = build_key(row: row)

        current_value = @hash.key?(key)
        @hash[key] = current_value ? Index.value(@hash[key], index) : index
      end
    end

    def build_key(row:)
      if @columns.count == 1
        row[@columns[0]]
      else
        @columns.map { |col| row[col] }
      end
    end
  end
end