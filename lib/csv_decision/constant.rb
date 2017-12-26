# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to recognise constant expressions in table cells.
  module Constant
    # Cell constant specified by prefixing the value with one of these 3 symbols
    EXPRESSION = Matchers.regexp("(?<operator>#{Matchers::EQUALS})\\s*(?<value>\\S.*)")

    # rubocop: disable Lint/BooleanSymbol
    NON_NUMERIC = {
      true: true,
      false: false,
      nil: nil
    }.freeze
    # rubocop: enable Lint/BooleanSymbol

    def self.matches?(cell)
      return false unless (match = EXPRESSION.match(cell))

      proc = non_numeric?(match)
      return proc if proc

      numeric?(match)
    end

    def self.proc(function:)
      Proc.with(type: :constant, function: function)
    end

    def self.numeric?(match)
      value = Matchers.to_numeric(match['value'])
      return false unless value

      proc(function: value)
    end

    def self.non_numeric?(match)
      name = match['value'].to_sym
      return false unless NON_NUMERIC.key?(name)

      proc(function: NON_NUMERIC[name])
    end
    private_class_method :non_numeric?
  end
end