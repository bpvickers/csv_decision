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

    def self.valid?(options)
      invalid_options = options.keys - VALID_OPTIONS

      return true if invalid_options.empty?

      raise ArgumentError, "invalid option(s) supplied: #{invalid_options.inspect}"
    end

    attr_accessor :attributes

    def initialize(options)
      Options.valid?(options)
      @attributes = Options.default(options)
    end
  end
end