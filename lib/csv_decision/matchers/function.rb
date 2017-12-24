# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells
  module Matchers
    # rubocop: disable Lint/BooleanSymbol
    NON_NUMERIC_CONSTANTS = {
      true: true,
      false:  false,
      nil: nil
    }.freeze
    # rubocop: enable Lint/BooleanSymbol

    # Function signature
    Signature = Value.new(:operator, :type, :name, :args, :negate)

    def self.cell_constant?(match)
      return false unless CELL_CONSTANT.member?(match['operator'])
      return false unless match['args'] == ''
      return false unless match['negate'] == ''

      constant?(match)
    end

    def self.constant?(match)
      name = match['name'].to_sym
      return false unless NON_NUMERIC_CONSTANTS.key?(name)

      Proc.with(type: :constant, function: NON_NUMERIC_CONSTANTS[name])
    end
    private_class_method :constant?

    def self.function?(match:, cell:)
      operator = match['operator']&.gsub(/\s+/, '')
      name = match['name'].to_sym
      args = match['args'].strip
      negate = match['negate'] == Matchers::NEGATE

      function = Symbol.function?(operator: operator, name: name, args: args)
      return function if function

      false
    end

    # Match cell against a function call or symbolic expression.
    class Function < Matcher
      # Looks like a function call or symbol expressions, e.g.,
      # == true
      # := function(arg: symbol)
      # == :column_name
      FUNCTION_CALL =
        "(?<operator>=|:=|==|=|<|>|!=|>=|<=|:|!\\s*:)\s*(?<negate>!?)\\s*(?<name>#{Header::COLUMN_NAME}|:)(?<args>.*)"
      FUNCTION_RE = Matchers.regexp(FUNCTION_CALL)

      def initialize(options = {})
        @options = options
      end

      def matches?(cell)
        match = FUNCTION_RE.match(cell)
        return false unless match

        # Check if the guard condition is a cell constant
        proc = Matchers.cell_constant?(match)
        return proc if proc

        Matchers.function?(match: match, cell: cell)
      end
    end
  end
end