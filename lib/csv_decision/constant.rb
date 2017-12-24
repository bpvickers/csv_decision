# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to recognise constant expressions
  module Constant
    # Cell constant specified by prefixing the value with these symbols
    OPERATOR = Set.new(%w[== := =]).freeze

    # rubocop: disable Lint/BooleanSymbol
    NON_NUMERIC = {
      true: true,
      false: false,
      nil: nil
    }.freeze
    # rubocop: enable Lint/BooleanSymbol

    def self.operator?(operator)
      OPERATOR.member?(operator)
    end

    def self.proc(function:)
      Proc.with(type: :constant, function: function)
    end

    def self.numeric?(operator:, cell:)
      return false unless operator?(operator)
      proc(function: cell)
    end

    def self.match?(match)
      return false unless OPERATOR.member?(match['operator'])
      return false unless match['args'] == ''
      return false unless match['negate'] == ''

      proc?(match)
    end

    def self.proc?(match)
      name = match['name'].to_sym
      return false unless NON_NUMERIC.key?(name)

      proc(function: NON_NUMERIC[name])
    end
    private_class_method :proc?
  end
end