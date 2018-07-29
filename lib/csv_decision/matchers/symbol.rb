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
    # Can also call a Ruby method on the column value - e.g, .blank? or !.blank?
    class Symbol < Matcher
      SYMBOL_COMPARATORS = "#{INEQUALITY}|>=|<=|<|>|#{EQUALS}"
      private_constant :SYMBOL_COMPARATORS

      # Column symbol comparison - e.g., > :column or != :column.
      # Can also be a method call - e.g., .present? or .blank?
      SYMBOL_COMPARE =
        "(?<comparator>#{SYMBOL_COMPARATORS})?\\s*(?<type>[.:!])?(?<name>#{Header::COLUMN_NAME})"
      private_constant :SYMBOL_COMPARE

      # Symbol comparision regular expression.
      SYMBOL_COMPARE_RE = Matchers.regexp(SYMBOL_COMPARE)
      private_constant :SYMBOL_COMPARE_RE

      # These procs compare one input hash value to another, and so do not coerce numeric values.
      # Note that we do *not* check +hash.key?(symbol)+, so a +nil+ value will match a missing
      # hash key.
      EQUALITY = {
        ':=' => proc { |symbol, value, hash| value == hash.dig(*symbol) },
        '!=' => proc { |symbol, value, hash| value != hash.dig(*symbol) }
      }.freeze
      private_constant :EQUALITY

      def self.compare_proc(sym)
        proc do |symbol, value, hash|
          Matchers.compare?(lhs: value, compare: sym, rhs: hash.dig(*symbol))
        end
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

      # E.g., > :col, we get comparator: >, name: col
      def self.comparison(comparator:, name:)
        function = COMPARE[comparator]
        Matchers::Proc.new(type: :symbol, function: function[name], symbols: [name])
      end
      private_class_method :comparison

      # E.g., !.nil?, we get comparator: !, name: nil?, type: .
      def self.method_call(comparator:, name:, type:)
        negate = negated_comparator?(comparator: comparator)
        return false if negate.nil?

        # Check for double negation - e.g., != !blank?
        negate = type == '!' ? !negate : negate
        method_function(name: name, negate: negate)
      end
      private_class_method :method_call

      def self.negated_comparator?(comparator:)
        # Do we have an equality comparator?
        if EQUALS_RE.match?(comparator)
          false

        # If do not have equality, do we have inequality?
        elsif INEQUALITY_RE.match?(comparator)
          true
        end
      end
      private_class_method :negated_comparator?

      # E.g., !.nil?, we get comparator: !, name: nil?
      def self.method_function(name:, negate:)
        # Allowed Ruby method names are a bit stricter than allowed decision table column names.
        return false unless METHOD_NAME_RE.match?(name)

        function = COMPARE[negate ? '!.' : '.']
        Matchers::Proc.new(type: :proc, function: function[name])
      end
      private_class_method :method_function

      def self.comparator_type(comparator:, name:, type:)
        if type == ':'
          comparison(comparator: comparator, name: name)

        # Method call - e.g, .blank? or !.present?
        # Can also take the forms: := .blank? or !=.present?
        else
          method_call(comparator: comparator, name: name[0], type: type || '.')
        end
      end
      private_class_method :comparator_type

      # @param (see Matchers::Matcher#matches?)
      # @return (see Matchers::Matcher#matches?)
      def self.matches?(cell)
        return false unless (match = SYMBOL_COMPARE_RE.match(cell))

        comparator = match['comparator']
        type = match['type']
        return false if comparator.nil? && type.nil?

        symbols = Matchers.path(match['name'])
        comparator_type(comparator: comparator || '=', type: type, name: symbols)
      end

      # @param (see Matcher#matches?)
      # @return (see Matcher#matches?)
      def matches?(cell)
        Symbol.matches?(cell)
      end
    end
  end
end