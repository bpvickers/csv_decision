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
    # Build the index on the designated input columns.
    def self.build(table:, options:)
      # Do we even have an index?
      keys = options[:index]
      return if keys.nil?

      key_cols = validate_index(columns: table.columns.ins, keys: keys)

      Index.new(table: table, keys: key_cols)
    end

    def self.validate_index(columns:, keys:)
      key_cols = validate_keys(columns: columns, keys: keys)
      return key_cols if key_cols

      raise TableValidationError, "option :index value of #{keys} exceeds number of input columns"
    end

    def self.validate_keys(columns:, keys:)
      return false if keys > columns.count

      validate_columns(columns: columns, keys: keys)
    end

    def self.validate_columns(columns:, keys:)
      count = 0
      key_cols = []
      columns.each_pair do |col, column|
        next if column.type == :guard

        key_cols << col
        return key_cols if (count += 1) == keys
      end

      false
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
    end

    # Current value is a row index integer
    def self.integer_value(current_value, index)
      # Is the new row index contiguous with the last start row/end row range?
      current_value + 1 == index ? [[current_value, index]] : [current_value, index]
    end

    # Current value is an array of row indexes
    def self.array_value(current_value, index)
      start_row, end_row = current_value.last

      end_row = start_row if end_row.nil?

      # Is the new row index contiguous with the last start row/end row range?
      end_row + 1 == index ? current_value[-1] = [start_row, index] : current_value << index
    end

    attr_reader :hash
    attr_reader :keys

    def initialize(table:, keys:)
      @keys = keys
      @hash = {}

      build(table)

      freeze
    end

    # TODO: Stub
    def build(table)
      table.each do |row, index|
        key = build_key(row: row, index: index)

        current_value = @hash.key?(key)
        @hash[key] = current_value ? Index.value(@hash[key], index) : index
      end
    end

    def build_key(row:, index:)
      if @keys.count == 1
        Index.simple_key(cell: row[@keys[0]], index: index)
      else
        @keys.map { |col| Index.simple_key(cell: row[col], index: index) }
      end
    end
  end
end