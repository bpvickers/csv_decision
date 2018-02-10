# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers.
# See LICENSE and README.md for details.
module CSVDecision
  # Match table data cells against a valid decision table expression or a simple constant.
  # @api private
  class Matchers
    # Composite object for a data cell proc. Note that we do not need it to be comparable.
    # Implemented as an immutable array of 2 or 3 entries for memory compactness and speed.
    # @api private
    class Proc < Array
      # @param type [Symbol] Type of the function value - e.g., :constant or :guard.
      # @param function [Object] Either a lambda function,
      #   or some kind of constant such as an Integer.
      # @param symbols [nil, Symbol, Array<Symbol>] The symbol or list of symbols
      #   that the function uses to reference input hash keys (which are always symbolized).
      def initialize(type:, function:, symbols: nil)
        super()

        self << type

        # Function values should always be frozen
        self << function.freeze

        # Some function values, such as constants or 0-arity functions, do not reference symbols.
        self << symbols if symbols

        freeze
      end

      # @param hash [Hash] Input hash to function call.
      # @param value [Object] Input value to function call.
      # @return [Object] Value returned from function call.
      def call(hash:, value: nil)
        func = fetch(1)

        return func.call(hash) if fetch(0) == :guard

        # All other procs can take one or two args
        func.arity == 1 ? func.call(value) : func.call(value, hash)
      end

      # @return [Symbol] Type of the function value - e.g., :constant or :guard.
      def type
        fetch(0)
      end

      # @return [Object] Either a lambda function, or some kind of constant such as an Integer.
      def function
        fetch(1)
      end

      # @return [nil, Symbol, Array<Symbol>] The symbol or list of symbols
      #   that the function uses to reference input hash keys (which are always symbolized).
      def symbols
        fetch(2, nil)
      end
    end

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

    # Symbols used for inequality
    INEQUALITY = '!=|!'

    # Match string for inequality
    INEQUALITY_RE = regexp(INEQUALITY)

    # Equality, cell constants and functions specified by prefixing the value with
    # one of these 3 symbols.
    EQUALS = '==|:=|='

    # Match string for equality
    EQUALS_RE = regexp(EQUALS)

    # Method names are stricter than CSV column names.
    METHOD_NAME_RE = /\A[_a-z][_a-z0-9]*[?!=]?\z/

    # Normalize the operators which are a variation on equals/assignment.
    #
    # @param operator [String]
    # @return [String]
    def self.normalize_operator(operator)
      EQUALS_RE.match?(operator) ? '==' : operator
    end

    # Regular expression used to recognise a numeric string with or without a decimal point.
    NUMERIC = '[-+]?\d*(?<decimal>\.?)\d*'

    NUMERIC_RE = regexp(NUMERIC)
    private_constant :NUMERIC_RE

    # Validate a numeric value and convert it to an Integer or BigDecimal if a valid numeric string.
    #
    # @param value [nil, String, Integer, BigDecimal]
    # @return [nil, Integer, BigDecimal]
    def self.numeric(value)
      return value if value.is_a?(Integer) || value.is_a?(BigDecimal)
      return unless value.is_a?(String)

      to_numeric(value)
    end

    # Convert a numeric string into an Integer or BigDecimal, otherwise return nil.
    #
    # @param value [String]
    # @return [nil, Integer, BigDecimal]
    def self.to_numeric(value)
      return unless (match = NUMERIC_RE.match(value))

      return value.to_i if match['decimal'] == ''
      BigDecimal(value.chomp('.'))
    end

    # Compare one object with another if they both respond to the compare method.
    #
    # @param lhs [Object]
    # @param compare [Object]
    # @param rhs [Object]
    # @return [nil, Boolean]
    def self.compare?(lhs:, compare:, rhs:)
      # Is the rhs the same class or a superclass of lhs, and does rhs respond to the
      # compare method?
      return lhs.send(compare, rhs) if lhs.is_a?(rhs.class) && rhs.respond_to?(compare)

      nil
    end

    # Parse the supplied input columns for the row supplied using an array of matchers.
    #
    # @param columns [Hash{Integer=>Columns::Entry}] Input columns hash.
    # @param matchers [Array<Matchers::Matcher>]
    # @param row [Array<String>] Data row being parsed.
    # @return [Array<(Array, ScanRow)>] Used to scan a table row against an input hash for matches.
    def self.parse(columns:, matchers:, row:)
      # Build an array of column indexes requiring simple constant matches,
      # and a second array of columns requiring special matchers.
      scan_row = ScanRow.new

      # Scan the columns in the data row, and build an object to scan this row against
      # an input hash.
      # Convert values in the data row if not just a simple constant.
      row = scan_row.scan_columns(columns: columns, matchers: matchers, row: row)

      [row, scan_row]
    end

    # @return [Array<Matchers::Matcher>] Matchers for the input columns.
    attr_reader :ins

    # @return [Array<Matchers::Matcher>] Matchers for the output columns.
    attr_reader :outs

    # @param options (see CSVDecision.parse)
    def initialize(options)
      matchers = options[:matchers].collect { |klass| klass.new(options) }
      @ins = matchers.select(&:ins?)
      @outs = matchers.select(&:outs?)
    end

    # Parse the row's input columns using the input matchers.
    #
    # @param columns (see Matchers.parse)
    # @param row (see Matchers.parse)
    # @return (see Matchers.parse)
    def parse_ins(columns:, row:)
      Matchers.parse(columns: columns, matchers: @ins, row: row)
    end

    # Parse the row's output columns using the output matchers.
    #
    # @param columns (see Matchers.parse)
    # @param row (see Matchers.parse)
    # @return (see Matchers.parse)
    def parse_outs(columns:, row:)
      Matchers.parse(columns: columns, matchers: @outs, row: row)
    end

    # Subclass and override {#matches?} to implement a custom Matcher class.
    class Matcher
      def initialize(_options = nil); end

      # Determine if the input cell string is recognised by this Matcher.
      #
      # @param cell [String] Data row cell.
      # @return [false, CSVDecision::Proc] Returns false if this cell is not a match; otherwise
      #   returns the +CSVDecision::Proc+ object indicating if this is a constant or some type of
      #   function.
      def matches?(cell); end

      # Does this matcher apply to output cells?
      #
      # @return [Boolean] Return true if this matcher applies to output cells,
      #   false otherwise.
      def outs?
        false
      end

      # Does this matcher apply to output cells?
      #
      # @return [Boolean] Return true if this matcher applies to input cells,
      #   false otherwise.
      def ins?
        true
      end
    end
  end
end