# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells.
  # @api private
  class Matchers
    # Match cells against Ruby-like range expressions or their negation -
    # e.g., +0...10+ or +!a..z+.
    class Range < Matcher
      # Match a table data cell string against a Ruby-like range expression.
      #
      # @param (see Matcher#matches?)
      # @return (see Matcher#matches?)
      def self.matches?(cell)
        if (match = NUMERIC_RANGE.match(cell))
          return range_proc(match: match, coerce: :to_numeric)
        end

        if (match = ALNUM_RANGE.match(cell))
          return range_proc(match: match)
        end

        false
      end

      # Range types are +..+ or +...+.
      TYPE = '(\.\.\.|\.\.)'
      private_constant :TYPE

      # Range expression looks like +0...10+ or +a..z+.
      # Can also be negated - e.g., +! 0..10+ or +!a..z+.
      def self.range_re(value)
        Matchers.regexp(
          "(?<negate>#{NEGATE}?)\\s*(?<min>#{value})(?<type>#{TYPE})(?<max>#{value})"
        )
      end
      private_class_method :range_re

      NUMERIC_RANGE = range_re(Matchers::NUMERIC)
      private_constant :NUMERIC_RANGE

      # Alphanumeric range, e.g., +a...z+ or +!a..c+.
      ALNUM_RANGE = range_re('[[:alnum:]][[:alnum:]]*')
      private_constant :ALNUM_RANGE

      # Coerce the string into a numeric value if required.
      def self.convert(value, method)
        method ? Matchers.send(method, value) : value
      end
      private_class_method :convert

      def self.range(match, coerce: nil)
        negate = match['negate'] == Matchers::NEGATE
        min = convert(match['min'], coerce)
        type = match['type']
        max = convert(match['max'], coerce)

        [negate, type == '...' ? min...max : min..max]
      end
      private_class_method :range

      # Build the lambda proc for a numeric range.
      def self.numeric_range(negate, range)
        return ->(value) { range.include?(Matchers.numeric(value)) } unless negate
        ->(value) { !range.include?(Matchers.numeric(value)) }
      end
      private_class_method :numeric_range

      # Build the lambda proc for an alphanumeric range.
      def self.alnum_range(negate, range)
        return ->(value) { range.include?(value) } unless negate
        ->(value) { !range.include?(value) }
      end
      private_class_method :alnum_range

      def self.range_proc(match:, coerce: nil)
        negate, range = range(match, coerce: coerce)
        method = coerce ? :numeric_range : :alnum_range
        function = Range.send(method, negate, range).freeze
        Proc.new(type: :proc, function: function)
      end
      private_class_method :range_proc

      # Ruby-like range expressions or their negation - e.g., +0...10+ or +!a..z+.
      #
      # @param (see Matcher#matches?)
      # @return (see Matcher#matches?)
      def matches?(cell)
        Range.matches?(cell)
      end
    end
  end
end