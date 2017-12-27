# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Recognise column symbol comparison expressions in input column data cells - e.g., +> :column+ or +!= :column+.
  module Symbol
    # Symbol comparison - e.g., > :column or != :column
    SYMBOL_COMPARE =
      "(?<comparator>#{Matchers::EQUALS}|!=|<|>|>=|<=)?\\s*:(?<name>#{Header::COLUMN_NAME})"
    private_constant :SYMBOL_COMPARE

    # Symbol comparision regular expression.
    SYMBOL_COMPARE_RE = Matchers.regexp(SYMBOL_COMPARE)
    private_constant :SYMBOL_COMPARE_RE

    # These procs compare one input hash value to another, and so do not coerce numeric values.
    # Note that we do *not* check +hash.key?(symbol)+, so a +nil+ value will match a missing hash key.
    EQUALITY = {
      ':=' => proc { |symbol, value, hash| value == hash[symbol] },
      '!=' => proc { |symbol, value, hash| value != hash[symbol] }
    }.freeze
    private_constant :EQUALITY

    def self.compare_proc(compare)
      proc { |symbol, value, hash| compare?(lhs: value, compare: compare, rhs: hash[symbol]) }
    end
    private_class_method :compare_proc

    COMPARE = {
      # Equality and inequality - create a lambda proc by calling with the actual column name symbol
      ':=' => ->(symbol) { EQUALITY[':='].curry[symbol].freeze },
      '='  => ->(symbol) { EQUALITY[':='].curry[symbol].freeze },
      '==' => ->(symbol) { EQUALITY[':='].curry[symbol].freeze },
      '!=' => ->(symbol) { EQUALITY['!='].curry[symbol].freeze },

      # Comparisons - create a lambda proc by calling with the actual column name symbol.
      '>'  => ->(symbol) { compare_proc(:'>' ).curry[symbol].freeze },
      '>=' => ->(symbol) { compare_proc(:'>=').curry[symbol].freeze },
      '<'  => ->(symbol) { compare_proc(:'<' ).curry[symbol].freeze },
      '<=' => ->(symbol) { compare_proc(:'<=').curry[symbol].freeze },
    }.freeze
    private_constant :COMPARE

    def self.compare?(lhs:, compare:, rhs:)
      # Is the rhs a superclass of lhs, and does rhs respond to the compare method?
      return lhs.public_send(compare, rhs) if lhs.is_a?(rhs.class) && rhs.respond_to?(compare)

      false
    end
    private_class_method :compare?

    # E.g., > :col, we get comparator: >, args: col
    def self.comparison(comparator:, name:)
      function = COMPARE[comparator]
      Proc.with(type: :symbol, function: function[name])
    end
    private_class_method :comparison

    # @param (see Matchers::Matcher#matches?)
    # @return (see Matchers::Matcher#matches?)
    def self.matches?(cell)
      match = SYMBOL_COMPARE_RE.match(cell)
      return false unless match

      comparator = match['comparator'] || '='
      name = match['name'].to_sym

      comparison(comparator: comparator, name: name)
    end
  end
end