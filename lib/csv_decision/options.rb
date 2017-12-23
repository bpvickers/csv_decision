# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Specialized cell value matchers beyond simple string compares.
  # By default all these matchers are tried in the specified order.
  DEFAULT_MATCHERS = [
    Matchers::Range,
    Matchers::Numeric,
    Matchers::Pattern
  ].freeze

  # All valid options with their default values.
  VALID_OPTIONS = {
    first_match: true,
    regexp_implicit: false,
    text_only: false,
    matchers: DEFAULT_MATCHERS
  }.freeze

  # These options may appear in the CSV file before the header row.
  # Convert them to a normalized option key value pair.
  CSV_OPTION_NAMES = {
    first_match: [:first_match, true],
    accumulate: [:first_match, false],
    regexp_implicit: [:regexp_implicit, true],
    text_only: [:text_only, true]
  }.freeze

  # Validate and normalize the options hash supplied.
  module Options
    # Validate options and supply default values for any options not explicitly set.
    #
    # @param options [Hash] - input options hash supplied
    # @return [Hash] - options hash filled in with all required default values
    def self.normalize(options)
      validate(options)
      default(options)
    end

    # Read any options supplied in the CSV file placed before the header row.
    #
    # @param rows [Array<Array<String>>] - table data rows.
    # @param options [Hash] - input options hash built so far
    # @return [Hash] - options hash overridden with any option values in the CSV file
    def self.from_csv(rows:, options:)
      row = rows.first
      return options if row.nil?

      # Have we hit the header row?
      return options if Header.row?(row)

      # Scan each cell looking for valid option values
      options = scan_cells(row: row, options: options)

      rows.shift
      from_csv(rows: rows, options: options)
    end

    def self.scan_cells(row:, options:)
      # Scan each cell looking for valid option values
      row.each do |cell|
        next if cell == ''

        key, value = option?(cell)
        options[key] = value if key
      end

      options
    end
    private_class_method :scan_cells

    def self.default(options)
      result = options.dup

      # The user may override the list of matchers to be used
      result[:matchers] = matchers(result)

      # Supply any missing options with default values
      VALID_OPTIONS.each_pair do |key, value|
        next if result.key?(key)
        result[key] = value
      end

      result
    end
    private_class_method :default

    def self.matchers(options)
      return [] if options.key?(:matchers) && !options[:matchers]
      return [] if options[:text_only]
      return DEFAULT_MATCHERS unless options.key?(:matchers)

      options[:matchers]
    end
    private_class_method :matchers

    def self.option?(cell)
      key = cell.downcase.to_sym
      return CSV_OPTION_NAMES[key] if CSV_OPTION_NAMES.key?(key)
    end
    private_class_method :option?

    def self.validate(options)
      invalid_options = options.keys - VALID_OPTIONS.keys

      return if invalid_options.empty?

      raise ArgumentError, "invalid option(s) supplied: #{invalid_options.inspect}"
    end
    private_class_method :validate
  end
end