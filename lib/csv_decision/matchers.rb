# frozen_string_literal: true

require 'values'

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Value object for a cell proc.
  Proc = Value.new(:type, :function)

  # Methods to assign a matcher to table data cells.
  class Matchers
    # Negation sign prefixed to ranges and functions.
    NEGATE = '!'

    # All regular expressions used for matching are anchored inside their own
    # non-capturing group.
    #
    # @param value [String] String used to form an anchored regular expression.
    # @return [Regexp] Anchored, frozen regular expression.
    def self.regexp(value)
      Regexp.new("\\A(?:#{value})\\z").freeze
    end

    # Regular expression used to recognise a numeric string with or without a decimal point.
    NUMERIC = '[-+]?\d*(?<decimal>\.?)\d*'
    NUMERIC_RE = regexp(NUMERIC)

    # @param value [Object] Value from the input hash.
    # @return [Boolean] Value is an Integer or a BigDecimal.
    def self.numeric?(value)
      value.is_a?(Integer) || value.is_a?(BigDecimal)
    end

    # Validate a numeric value and convert it to an Integer or BigDecimal if a valid numeric string.
    #
    # @param value [nil, String, Integer, BigDecimal]
    # @return [nil, Integer, BigDecimal]
    def self.numeric(value)
      return value if numeric?(value)
      return unless value.is_a?(String)

      to_numeric(value)
    end

    # Convert a numeric string into an Integer or BigDecimal.
    #
    # @param value [String]
    # @return [nil, Integer, BigDecimal]
    def self.to_numeric(value)
      return unless (match = NUMERIC_RE.match(value))
      coerce_numeric(match, value)
    end

    def self.coerce_numeric(match, value)
      return value.to_i if match['decimal'] == ''
      BigDecimal(value.chomp('.'))
    end
    private_class_method :coerce_numeric

    # Parse the supplied input columns for the row supplied using an array of matchers.
    #
    # @param columns [Hash{Integer=>Columns::Entry}] Input columns hash.
    # @param matchers [Array<Matchers::Matcher>]
    # @param row [Array] Data row being parsed.
    # @return [ScanRow] Used to scan a table row against an input hash for matches.
    def self.parse(columns:, matchers:, row:)
      # Build an array of column indexes requiring simple constant matches,
      # and a second array of columns requiring special matchers.
      scan_row = ScanRow.new

      # scan_columns(columns: columns, matchers: matchers, row: row, scan_row: scan_row)
      scan_row.scan_columns(columns: columns, matchers: matchers, row: row)

      scan_row.freeze
    end

    # Scan the table cell against all matches.
    #
    # @param matchers [Array<Matchers::Matcher>]
    # @param cell [String]
    # @return [false, Matchers::Proc]
    def self.scan(matchers:, cell:)
      matchers.each do |matcher|
        proc = matcher.matches?(cell)
        return proc if proc
      end

      # Must be a simple constant
      false
    end

    def self.ins_matchers(options)
      options[:matchers].collect { |klass| klass.new(options) }
    end

    def self.outs_matchers(matchers)
      matchers.select { |obj| OUTS_MATCHERS.include?(obj.class) }
    end

    attr_reader :ins
    attr_reader :outs

    def initialize(options)
      @ins = Matchers.ins_matchers(options)
      @outs = Matchers.outs_matchers(@ins)
    end

    def parse_ins(columns:, row:)
      Matchers.parse(columns: columns, matchers: @ins, row: row)
    end

    def parse_outs(columns:, row:)
      Matchers.parse(columns: columns, matchers: @outs, row: row)
    end

    # @abstract Subclass and override {#matches?} to implement
    #   a custom Matcher class.
    class Matcher
      def initialize(_options = nil); end

      def matches?(_cell); end
    end
  end
end