# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  VALID_OPTIONS = %i[
    force_encoding
    ascii_only?
    first_match
    regexp_implict
    text_only
    index
    tables
  ].freeze

  OPTION_DEFAULTS = {
    force_encoding: 'UTF-8',
    ascii_only?: true,
    first_match: true,
    regexp_implict: false,
    text_only: false
  }.freeze

  CSV_OPTION_NAMES = {
    first_match: [:first_match, true],
    accumulate: [:first_match, true],
    regexp_implict: [:regexp_implict, true],
    text_only: [:text_only, true]
  }.freeze

  # Parse the CSV file and create a new decision table object
  class Options
    def self.default(options)
      result = options.deep_dup

      # Default any missing options that have defaults defined
      OPTION_DEFAULTS.each_pair do |key, value|
        next if result.key?(key)
        result[key] = value
      end

      result
    end

    def self.cell?(cell)
      return false if cell == ''

      key = cell.downcase.to_sym
      return CSV_OPTION_NAMES[key] if CSV_OPTION_NAMES.key?(key)
    end

    def self.valid?(options)
      invalid_options = options.keys - VALID_OPTIONS

      return true if invalid_options.empty?

      raise ArgumentError, "invalid option(s) supplied: #{invalid_options.inspect}"
    end

    def self.from_csv(table, attributes)
      row = table.rows.first
      return attributes if row.nil?

      return attributes if ParseHeader.row?(row)

      row.each do |cell|
        key, value = Options.cell?(cell)
        attributes[key] = value if key
      end

      table.rows.shift
      from_csv(table, attributes)
    end

    attr_accessor :attributes

    def initialize(options)
      Options.valid?(options)
      @attributes = Options.default(options)
    end

    def from_csv(table)
      # Options on the CSV file override the ones passed into the method
      @attributes = Options.from_csv(table, @attributes)

      self
    end
  end
end