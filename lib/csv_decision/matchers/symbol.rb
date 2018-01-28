# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Recognise expressions in table data cells.
  # @api private
  class Matchers
    # Match cell against a symbolic expression - e.g., :column, > :column.
    # Can also call a Ruby method pn the column value - e.g, .blank? or !.blank?
    class Symbol < Matcher
      SYMBOL_COMPARATORS = "#{INEQUALITY}|>=|<=|<|>|#{EQUALS}"
      private_constant :SYMBOL_COMPARATORS

      # Column symbol comparison - e.g., > :column or != :column.
      # Can also be a method call - e.g., .present? or .blank?
      SYMBOL_COMPARE =
        "(?<comparator>#{SYMBOL_COMPARATORS})?\\s*(?<type>[.:])(?<name>#{Header::COLUMN_NAME})"
      private_constant :SYMBOL_COMPARE

      # Symbol comparision regular expression.
      SYMBOL_COMPARE_RE = Matchers.regexp(SYMBOL_COMPARE)
      private_constant :SYMBOL_COMPARE_RE

      # These procs compare one input hash value to another, and so do not coerce numeric values.
      # Note that we do *not* check +hash.key?(symbol)+, so a +nil+ value will match a missing
      # hash key.
      EQUALITY = {
        ':=' => proc { |symbol, value, hash| value == hash[symbol] },
        '!=' => proc { |symbol, value, hash| value != hash[symbol] }
      }.freeze
      private_constant :EQUALITY

      def self.compare_proc(compare)
        proc { |symbol, value, hash| compare?(lhs: value, compare: compare, rhs: hash[symbol]) }
      end
      private_class_method :compare_proc

      def self.value_method(value, method)
        value.respond_to?(method) && value.send(method)
      end
      private_class_method :value_method

      def self.method_proc(negate:)
        if negate
          proc { |symbol, value| !value_method(value, symbol) }
        else
          proc { |symbol, value|  value_method(value, symbol) }
        end
      end
      private_class_method :method_proc

      COMPARE = {
        # Equality and inequality - create a lambda proc by calling with the actual column name
        # symbol.
        ':=' => ->(symbol) { EQUALITY[':='].curry[symbol].freeze },
        '='  => ->(symbol) { EQUALITY[':='].curry[symbol].freeze },
        '==' => ->(symbol) { EQUALITY[':='].curry[symbol].freeze },
        '!=' => ->(symbol) { EQUALITY['!='].curry[symbol].freeze },
        '!'  => ->(symbol) { EQUALITY['!='].curry[symbol].freeze },

        # Comparisons - create a lambda proc by calling with the actual column name symbol.
        '>'  => ->(symbol) { compare_proc(:'>').curry[symbol].freeze },
        '>=' => ->(symbol) { compare_proc(:'>=').curry[symbol].freeze },
        '<'  => ->(symbol) { compare_proc(:'<').curry[symbol].freeze },
        '<=' => ->(symbol) { compare_proc(:'<=').curry[symbol].freeze },

        # 0-arity Ruby method calls applied to an input column value.
        '.'  => ->(symbol) { method_proc(negate: false).curry[symbol].freeze },
        '!.' => ->(symbol) { method_proc(negate: true).curry[symbol].freeze }
      }.freeze
      private_constant :COMPARE

      def self.compare?(lhs:, compare:, rhs:)
        # Is the rhs a superclass of lhs, and does rhs respond to the compare method?
        return lhs.public_send(compare, rhs) if lhs.is_a?(rhs.class) && rhs.respond_to?(compare)

        false
      end
      private_class_method :compare?

      # E.g., > :col, we get comparator: >, name: col
      def self.comparison(comparator:, name:)
        function = COMPARE[comparator]
        Matchers::Proc.new(type: :symbol, function: function[name], symbols: name)
      end
      private_class_method :comparison

      # E.g., !.nil?, we get comparator: !, name: nil?
      def self.method_call(comparator:, name:)
        equality = EQUALS_RE.match?(comparator)
        inequality = equality ? false : INEQUALITY_RE.match?(comparator)

        return false unless equality || inequality

        # Allowed Ruby method names are a bit stricter than allowed decision table column names.
        return false unless METHOD_NAME_RE.match?(name)

        function = COMPARE[equality ? '.' : '!.']
        Matchers::Proc.new(type: :proc, function: function[name])
      end
      private_class_method :method_call

      # @param (see Matchers::Matcher#matches?)
      # @return (see Matchers::Matcher#matches?)
      def self.matches?(cell)
        return false unless (match = SYMBOL_COMPARE_RE.match(cell))

        comparator = match['comparator'] || '='
        name = match['name'].to_sym
        if match['type'] == ':'
          comparison(comparator: comparator, name: name)

        # Method call - e.g, .blank? or !.present?
        # Can also take the forms: := .blank? or !=.present?
        else
          method_call(comparator: comparator, name: name)
        end
      end

      # @param (see Matcher#matches?)
      # @return (see Matcher#matches?)
      def matches?(cell)
        Symbol.matches?(cell)
      end
    end
  end
end