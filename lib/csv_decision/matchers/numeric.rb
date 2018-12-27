# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells.
  # @api private
  class Matchers
    # Recognise numeric comparison expressions - e.g., +> 100+ or +!= 0+.
    class Numeric < Matcher
      # For example: +>= 100+ or +!= 0+.
      COMPARISON = /\A(?<comparator><=|>=|<|>|!=)\s*(?<value>\S.*)\z/
      private_constant :COMPARISON

      # Coerce the input value to a numeric representation before invoking the comparison.
      # If the coercion fails, it will produce a nil value which always fails to match.
      COMPARATORS = {
        '>'  => proc { |numeric_cell, value| Matchers.numeric(value)&.>  numeric_cell },
        '>=' => proc { |numeric_cell, value| Matchers.numeric(value)&.>= numeric_cell },
        '<'  => proc { |numeric_cell, value| Matchers.numeric(value)&.<  numeric_cell },
        '<=' => proc { |numeric_cell, value| Matchers.numeric(value)&.<= numeric_cell },
        '!=' => proc { |numeric_cell, value| Matchers.numeric(value)&.!= numeric_cell }
      }.freeze
      private_constant :COMPARATORS

      # (see Matcher#matches?)
      def self.matches?(cell)
        return false unless (match = COMPARISON.match(cell))
        return false unless (numeric_cell = Matchers.to_numeric(match['value']))

        comparator = match['comparator']
        Matchers::Proc.new(type: :proc,
                           function: COMPARATORS[comparator].curry[numeric_cell].freeze)
      end

      # (see Matcher#matches?)
      def matches?(cell, _path = [])
        Numeric.matches?(cell)
      end
    end
  end
end