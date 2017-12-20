# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  VALID_OPTIONS = {
    first_match: true,
    regexp_implicit: false,
    text_only: false,
    index: nil,
    matchers: [],
    tables: nil
  }.freeze

  CSV_OPTION_NAMES = {
    first_match: [:first_match, true],
    accumulate: [:first_match, false],
    regexp_implicit: [:regexp_implicit, true],
    text_only: [:text_only, true]
  }.freeze

  # Specialized cell value matchers beyond simple string compares.
  # By default these matchers are tried in the specified order.
  DEFAULT_MATCHERS = [
    Matchers::Range,
    Matchers::Numeric,
    Matchers::Pattern
  ].freeze

  # Parse the CSV file and create a new decision table object
  module Options
    def self.default(options)
      result = options.deep_dup

      result[:matchers] = matchers(result)

      # Default any missing options with defaults
      VALID_OPTIONS.each_pair do |key, value|
        next if result.key?(key)
        result[key] = value
      end

      result
    end

    def self.matchers(options)
      return [] if options.key?(:matchers) && !options[:matchers]
      return [] if options[:text_only]
      return DEFAULT_MATCHERS unless options.key?(:matchers)

      options[:matchers]
    end

    def self.cell?(cell)
      key = cell.downcase.to_sym
      return CSV_OPTION_NAMES[key] if CSV_OPTION_NAMES.key?(key)
    end

    def self.validate(options)
      invalid_options = options.keys - VALID_OPTIONS.keys

      return if invalid_options.empty?

      raise ArgumentError, "invalid option(s) supplied: #{invalid_options.inspect}"
    end

    def self.from_csv(table:, attributes:)
      row = table.rows.first
      return attributes if row.nil?

      # Have we hit the header row?
      return attributes if Header.row?(row)

      row.each do |cell|
        next if cell == ''
        key, value = Options.cell?(cell)
        attributes[key] = value if key
      end

      table.rows.shift
      from_csv(table: table, attributes: attributes)
    end

    def self.normalize(options)
      validate(options)
      default(options)
    end
  end
end