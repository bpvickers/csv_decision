# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Recognise constant expressions in table data cells.
  module Constant
    # Cell constant expression specified by prefixing the value with one of the three equality symbols.
    EXPRESSION = Matchers.regexp("(?<operator>#{Matchers::EQUALS})\\s*(?<value>\\S.*)")
    private_constant :EXPRESSION

    # rubocop: disable Lint/BooleanSymbol

    # Non-numeric constants recognised by CSV Decision.
    NON_NUMERIC = {
      nil: nil,
      true: true,
      false: false
    }.freeze
    private_constant :NON_NUMERIC
    # rubocop: enable Lint/BooleanSymbol

    # @param (see Matchers::Matcher#matches?)
    # @return (see Matchers::Matcher#matches?)
    def self.matches?(cell)
      return false unless (match = EXPRESSION.match(cell))

      proc = non_numeric?(match)
      return proc if proc

      numeric?(match)
    end

    def self.proc(function:)
      Proc.with(type: :constant, function: function)
    end
    private_class_method :proc

    def self.numeric?(match)
      value = Matchers.to_numeric(match['value'])
      return false unless value

      proc(function: value)
    end
    private_class_method :numeric?

    def self.non_numeric?(match)
      name = match['value'].to_sym
      return false unless NON_NUMERIC.key?(name)

      proc(function: NON_NUMERIC[name])
    end
    private_class_method :non_numeric?
  end
end