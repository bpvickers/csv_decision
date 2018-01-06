# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the input hash.
  # @api private
  module Input
    # @param (see Decide.decide)
    # @return [Hash{Symbol => Hash{Symbol=>Object}, Hash{Integer=>Object}}]
    #   Returns  a hash of two hashes:
    #   * hash: either a copy with keys symbolized or the original input object
    #   * scan_cols: Picks out the value in the input hash for each table input column.
    #     Defaults to nil if the key is missing in the input hash.
    def self.parse(table:, input:, symbolize_keys:)
      validate(input)

      parse_input(table: table, input: input(table, input, symbolize_keys))
    end

    def self.input(table, input, symbolize_keys)
      input_keys = table.columns.input_keys

      # For safety the default is to symbolize the keys of a copy of the input hash.
      if symbolize_keys
        input = input.symbolize_keys
        input.slice!(*input_keys)
        return input
      end

      # However, if this is turned off then the keys should already symbolized,
      # so just return a copy of the input hash slice we need.
      input.slice(*input_keys)
    end
    private_class_method :input

    def self.validate(input)
      return if input.is_a?(Hash) && !input.empty?
      raise ArgumentError, 'input must be a non-empty hash'
    end
    private_class_method :validate

    def self.parse_input(table:, input:)
      scan_cols = {}

      # TODO: Does this table have any defaulted columns?
      # defaulted_columns = table.columns[:defaults]

      table.columns.ins.each_pair do |col, column|
        value = input[column.name]

        scan_cols[col] = value
      end

      { hash: input.freeze, scan_cols: scan_cols }.freeze
    end
    private_class_method :parse_input
  end
end