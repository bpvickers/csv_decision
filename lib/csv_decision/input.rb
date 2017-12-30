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

      # For safety the default is to symbolize keys and make a copy of the hash.
      # However, if this is turned off then the keys must already symbolized.
      input = symbolize_keys ? input.symbolize_keys : input

      parsed_input = parse_input(table: table, input: input)

      # Freeze the copy of the input hash we just created.
      parsed_input[:hash].freeze if symbolize_keys

      parsed_input.freeze
    end

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

      { hash: input, scan_cols: scan_cols }
    end
    private_class_method :parse_input
  end
end