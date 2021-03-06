# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Recognise expressions in table data cells.
  # @api private
  class Matchers
    # Match cell against a column symbol guard expression -
    # e.g., +>:column.present?+ or +:column == 100.0+.
    class Guard < Matcher
      # Column symbol expression - e.g., +>:column+ or +:!column+.
      SYMBOL_RE =
        Matchers.regexp("(?<negate>#{Matchers::NEGATE}?)\\s*:(?<name>#{Header::COLUMN_NAME})")
      private_constant :SYMBOL_RE

      # Column symbol guard expression - e.g., +>:column.present?+ or +:column == 100.0+.
      GUARD_RE = Matchers.regexp(
        "(?<negate>#{Matchers::NEGATE}?)\\s*" \
        ":(?<name>#{Header::COLUMN_NAME})\\s*" \
        "(?<method>!=|=~|!~|<=|>=|>|<|#{Matchers::EQUALS}|\\.)\\s*" \
        "(?<param>\\S.*)"
      )
      private_constant :GUARD_RE

      # Negated methods
      NEGATION = { '=' => '!=', '==' => '!=', ':=' => '!=', '!=' => '=',
                   '>' => '<=', '>=' => '<', '<' => '>=', '<=' => '>',
                   '.' => '!.',
                   '=~' => '!~', '!~' => '=~' }.freeze
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

      def self.symbol_function(symbol, method, hash)
        hash[symbol].respond_to?(method) && hash[symbol].send(method)
      end
      private_class_method :symbol_function

      def self.regexp_match(symbol, value, hash)
        return false unless value.is_a?(String)
        data = hash[symbol]
        data.is_a?(String) && Matchers.regexp(value).match?(data)
      end
      private_class_method :regexp_match

      FUNCTION = {
        '.'  => proc { |symbol, method, hash|  symbol_function(symbol, method, hash) },
        '!.' => proc { |symbol, method, hash| !symbol_function(symbol, method, hash) },
        '=~' => proc { |symbol, value, hash|  regexp_match(symbol, value, hash) },
        '!~' => proc { |symbol, value, hash| !regexp_match(symbol, value, hash) }
      }.freeze
      private_constant :FUNCTION

      SYMBOL_PROC = {
        ':'  => proc { |symbol, hash|  hash[symbol] },
        '!:' => proc { |symbol, hash| !hash[symbol] }
      }.freeze
      private_constant :SYMBOL_PROC

      def self.non_numeric(method)
        proc = FUNCTION[method]
        return proc if proc

        proc { |symbol, value, hash| Matchers.compare?(lhs: hash[symbol], compare: method, rhs: value) }
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
        Matchers::Proc.new(type: :guard, symbols: symbol, function: proc.curry[symbol].freeze)
      end
      private_class_method :symbol_proc

      def self.symbol_guard(cell)
        match = GUARD_RE.match(cell)
        return false unless match

        proc, value = guard_proc(match)
        symbol = match['name'].to_sym
        Matchers::Proc.new(type: :guard, symbols: symbol,
                           function: proc.curry[symbol][value].freeze)
      end
      private_class_method :symbol_guard

      # (see Matcher#matches?)
      def self.matches?(cell)
        proc = symbol_proc(cell)
        return proc if proc

        symbol_guard(cell)
      end

      # @param (see Matcher#matches?)
      # @return (see Matcher#matches?)
      def matches?(cell)
        Guard.matches?(cell)
      end

      # @return (see Matcher#outs?)
      def outs?
        true
      end
    end
  end
end