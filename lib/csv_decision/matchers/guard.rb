# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Recognise expressions in table data cells.
  class Matchers
    # Match cell against a column symbol guard expression - e.g., +>:column.present?+ or +:column == 100.0+.
    class Guard < Matcher
      # Column symbol expression - e.g., +>:column+ or +:!column+.
      SYMBOL =
        "(?<negate>#{Matchers::NEGATE}?)\\s*:(?<name>#{Header::COLUMN_NAME})"
      private_constant :SYMBOL

      SYMBOL_RE = Matchers.regexp(SYMBOL)
      private_constant :SYMBOL_RE

      # Column symbol guard expression - e.g., +>:column.present?+ or +:column == 100.0+.
      GUARD =
        "(?<negate>#{Matchers::NEGATE}?)\\s*" \
      ":(?<name>#{Header::COLUMN_NAME})\\s*" \
      "(?<method>#{Matchers::EQUALS}|!=|<=|>=|>|<|\\.)\\s*" \
      "(?<param>\\S.*)"
      private_constant :GUARD

      GUARD_RE = Matchers.regexp(GUARD)
      private_constant :GUARD_RE

      # Negated methods
      NEGATION = {
        '='  => '!=',
        '==' => '!=',
        ':=' => '!=',
        '.'  => '!.',
        '!=' => '=',
        '>'  => '<=',
        '>=' => '<',
        '<'  => '>=',
        '<=' => '>'
      }.freeze
      private_constant :NEGATION

      # Note: value has already been converted to an Integer or BigDecimal.
      NUMERIC_COMPARE = {
        '=='  => proc { |symbol, value, hash| Matchers.numeric(hash[symbol])   == value },
        '!='  => proc { |symbol, value, hash| Matchers.numeric(hash[symbol])   != value },
        '>'   => proc { |symbol, value, hash| Matchers.numeric(hash[symbol]) &.>  value },
        '>='  => proc { |symbol, value, hash| Matchers.numeric(hash[symbol]) &.>= value },
        '<'   => proc { |symbol, value, hash| Matchers.numeric(hash[symbol]) &.<  value },
        '<='  => proc { |symbol, value, hash| Matchers.numeric(hash[symbol]) &.<= value }
      }.freeze
      private_constant :NUMERIC_COMPARE

      FUNCTION = {
        '.'  => proc { |symbol, value, hash|   hash[symbol].respond_to?(value) && hash[symbol].send(value) },
        '!.' => proc { |symbol, value, hash| !(hash[symbol].respond_to?(value) && hash[symbol].send(value)) },
      }.freeze
      private_constant :FUNCTION

      SYMBOL_PROC = {
        ':'  => proc { |symbol, hash|  hash[symbol] },
        '!:' => proc { |symbol, hash| !hash[symbol] },
      }.freeze
      private_constant :SYMBOL_PROC

      def self.compare?(lhs:, compare:, rhs:)
        # Is the rhs the same class or a superclass of lhs, and does rhs respond to the compare method?
        return lhs.send(compare, rhs) if lhs.is_a?(rhs.class) && rhs.respond_to?(compare)

        nil
      end
      private_class_method :compare?

      def self.non_numeric(method)
        proc = FUNCTION[method]
        return proc if proc

        return proc { |symbol, value, hash| compare?(lhs: hash[symbol], compare: method, rhs: value) }
      end
      private_class_method :non_numeric

      def self.method(match)
        method = match['method']
        match['negate'].present? ? NEGATION[method] : Matchers.normalize_operator(method)
      end
      private_class_method :method

      def self.guard_proc(match)
        method = method(match)
        param =  match['param']

        # If the parameter is a numeric value then use numeric compares rather than string compares.
        if (value = Matchers.to_numeric(param))
          return [NUMERIC_COMPARE[method], value]
        end

        # Process a non-numeric method where the param is just a string
        [non_numeric(method), param]
      end
      private_class_method :guard_proc

      def self.symbol_proc(cell)
        match = SYMBOL_RE.match(cell)
        return false unless match

        method = match['negate'].present? ? '!:' : ':'
        proc = SYMBOL_PROC[method]
        symbol = match['name'].to_sym
        Matchers::Proc.with(type: :guard, function: proc.curry[symbol].freeze)
      end
      private_class_method :symbol_proc

      def self.symbol_guard(cell)
        match = GUARD_RE.match(cell)
        return false unless match

        proc, value = guard_proc(match)
        symbol = match['name'].to_sym
        Matchers::Proc.with(type: :guard, function: proc.curry[symbol][value].freeze)
      end
      private_class_method :symbol_guard

      # (see Matchers::Matcher#matches?)
      def self.matches?(cell)
        proc = symbol_proc(cell)
        return proc if proc

        symbol_guard(cell)
      end

      # @param (see Matcher#matches?)
      # @return (see Matcher#matches?)
      def matches?(cell)
        Matchers::Guard.matches?(cell)
      end

      # @return (see Matcher#outs?)
      def outs?
        true
      end
    end
  end
end