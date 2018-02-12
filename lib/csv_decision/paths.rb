# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers.
# See LICENSE and README.md for details.
module CSVDecision
  # Build an index for a decision table with one or more input columns
  # designated as keys
  # @api private
  class Paths
    # Build the index of paths
    #
    # @param table [CSVDecision::Table] Decision table being indexed.
    # @return [CSVDecision::Paths] The built index of paths.
    def self.scan(table:)
      # Do we even have paths?
      columns = table.columns.paths.keys
      return [] if columns.empty?

      table.paths = Paths.new(table: table, columns: columns).paths
    end

    # @param current_value [Integer, Array] Current path value.
    # @param index [Integer] Array row index to be included in the path entry.
    # @return [Integer, Array] New path key value.
    def self.value(current_value, index)
      return [current_value, index] if current_value.is_a?(Integer)

      current_value[-1] = index
      current_value
    end

    # @param value [String] Cell value for the path: column.
    # @return [nil, Symbol] Non-empty string converted to a symbol.
    def self.symbol(value)
      value.blank? ? nil : value.to_sym
    end

    # @return [Hash] The index hash mapping in input values to one or more data array row indexes.
    attr_reader :paths

    # @param table [CSVDecision::Table] Decision table.
    # @param columns [Array<Index>] Array of column indexes to be indexed.
    def initialize(table:, columns:)
      @paths = []
      @columns = columns

      build(table)

      freeze
    end

    private

    def build(table)
      last_path = nil
      key = -1
      rows = nil
      table.each do |row, index|
        path = build_path(row: row)
        if path == last_path
          rows = Paths.value(rows, index)
        else
          rows = index
          key += 1
          last_path = path
        end

        @paths[key] = [path, rows]
      end
    end

    def build_path(row:)
      @columns.map { |col| Paths.symbol(row[col]) }.compact
    end
  end
end