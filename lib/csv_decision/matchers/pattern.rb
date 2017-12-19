# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells
  module Matchers
    # Match cell against a regular expression pattern
    class Pattern
      EXPLICIT_COMPARISON = /\A(?<comparator>=~|!~|!=)\s*(?<value>\S.*)\z/
      IMPLICIT_COMPARISON = /\A(?<comparator>=~|!~|!=)?\s*(?<value>\S.*)\z/

      # rubocop: disable Style/DoubleNegation
      PATTERN_LAMBDAS = {
        '!=' => proc { |pattern, value|   pattern != value }.freeze,
        '=~' => proc { |pattern, value| !!pattern.match(value) }.freeze,
        '!~' => proc { |pattern, value|  !pattern.match(value) }.freeze
      }.freeze
      # rubocop: enable Style/DoubleNegation

      def self.regexp?(cell:, explicit:)
        # By default a regexp pattern must use an explicit comparator
        match = explicit ? EXPLICIT_COMPARISON.match(cell) : IMPLICIT_COMPARISON.match(cell)
        return false if match.nil?

        comparator = match['comparator']

        # Comparator may be omitted if the regexp_explicit option is off.
        return false if explicit && comparator.nil?

        parse(comparator: comparator, value: match['value'])
      end

      def self.parse(comparator:, value:)
        return false if value.blank?

        # We cannot do a regexp comparison against a symbol name.
        # (Maybe we should add this feature?)
        return if value[0] == ':'

        # If no comparator then the implicit option must be on
        if comparator.nil?
          # rubocop: disable Style/CaseEquality
          return unless /\W/ === value
          # rubocop: enable Style/CaseEquality

          # Make the implict comparator explict
          comparator = '=~'
        end

        [comparator, value]
      end

      def initialize(options = {})
        # By default regexp's must have an explicit comparator
        @regexp_explicit = !options[:regexp_implicit]
      end

      def matches?(cell)
        return false if cell == ''

        comparator, value = Pattern.regexp?(cell: cell, explicit: @regexp_explicit)

        # We could not find a regexp pattern - maybe it's a simple string or something else?
        return false unless comparator

        # No need for a regular expression if we have simple string inequality
        pattern = comparator == '!=' ? value : Matchers.regexp(value)

        Proc.with(type: :proc,
                  function: PATTERN_LAMBDAS[comparator].curry[pattern].freeze)
      end
    end
  end
end