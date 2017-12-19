# frozen_string_literal: true

require 'ice_nine'
require 'ice_nine/core_ext/object'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the input hash
  module Input
    def self.parse(table:, input:, symbolize_keys:)
      validate(input)

      # For safety the default is to symbolize keys and make a copy of the hash.
      # However, if this is turned off assume keys are symbolized
      # TODO: Is it OK to mutate the hash in this case?
      input = symbolize_keys ? input.deep_symbolize_keys : input

      parsed_input = parse_input(table: table, input: input)

      parsed_input[:hash].deep_freeze if symbolize_keys

      parsed_input
    end

    def self.validate(input)
      return if input.is_a?(Hash) && !input.empty?
      raise ArgumentError, 'input must be a non-empty hash'
    end
    private_class_method :validate

    def self.parse_input(table:, input:)
      scan_cols = {}
      defaults = {}

      # Does this table have any defaulted columns?
      # defaulted_columns = table.columns[:defaults]

      table.columns.ins.each_pair do |col, column|
        value = input[column[:name]]

        scan_cols[col] = value
      end

      { hash: input, scan_cols: scan_cols, defaults: defaults.freeze }
    end
  end
end