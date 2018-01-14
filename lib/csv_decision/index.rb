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
    # @param index [nil, Integer] If specified, then the option value is a positive integer giving
    #   the number of input columns, scanning from left to right, to be included in the index.
    # @return [CSVDecision::Index] The built index.
    def self.build(table:, index:)
      # Do we even have an index? If specified, then the option value is a positive integer giving
      # the number of input columns, scanning from left to right, to be included in the index.
      # Guard columns will be skipped.
      return if index.nil?

      key_cols = validate_index(columns: table.columns.ins, index: index)

      Index.new(table: table, columns: key_cols)
    end

    def self.simple_key(cell:, index:)
      raise 'an empty string' if cell == ''

      return cell unless cell.is_a?(Matchers::Proc)

      raise 'a functional expression'
    rescue StandardError => error
      raise CellValidationError, "key value is #{error} in row ##{index + 1}"
    end

    def self.value(current_value, index)
      return integer_value(current_value, index) if current_value.is_a?(Integer)

      array_value(current_value, index)

      current_value
    end

    def self.validate_index(columns:, index:)
      key_cols = validate_keys(columns: columns, index: index)
      return key_cols if key_cols

      raise TableValidationError, "option :index value of #{index} exceeds number of input columns"
    end
    private_class_method :validate_index

    def self.validate_keys(columns:, index:)
      return false if index > columns.count

      validate_columns(columns: columns, index: index)
    end
    private_class_method :validate_keys

    def self.validate_columns(columns:, index:)
      count = 0
      key_cols = []
      columns.each_pair do |col, column|
        next if column.type == :guard

        key_cols << col
        return key_cols if (count += 1) == index
      end

      false
    end
    private_class_method :validate_columns

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

    def initialize(table:, columns:)
      @columns = columns
      @hash = {}

      build(table)

      freeze
    end

    private

    def build(table)
      table.each do |row, index|
        key = build_key(row: row, index: index)

        current_value = @hash.key?(key)
        @hash[key] = current_value ? Index.value(@hash[key], index) : index
      end
    end

    def build_key(row:, index:)
      if @columns.count == 1
        Index.simple_key(cell: row[@columns[0]], index: index)
      else
        @columns.map { |col| Index.simple_key(cell: row[col], index: index) }
      end
    end
  end
end