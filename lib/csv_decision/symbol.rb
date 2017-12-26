# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods dealing with column symbol comparisons in cells
  module Symbol
    SYMBOL_COMPARE =
      "(?<comparator>#{Matchers::EQUALS}|!=|<|>|>=|<=)?\\s*:(?<name>#{Header::COLUMN_NAME})"

    SYMBOL_COMPARE_RE = Matchers.regexp(SYMBOL_COMPARE)

    # These procs compare one input hash value to another, and so do not coerce.
    # Note that we do check hash.key?(symbol), so a nil value will match a missing hash key.
    EQUALITY = {
      ':=' => proc { |symbol, value, hash| value == hash[symbol] },
      '!=' => proc { |symbol, value, hash| value != hash[symbol] }
    }.freeze

    def self.compare_proc(compare)
      proc { |symbol, value, hash| compare?(lhs: value, compare: compare, rhs: hash[symbol]) }
    end

    COMPARE = {
      # Equality and inequality
      ':=' => ->(symbol) { EQUALITY[':='].curry[symbol].freeze },
      '='  => ->(symbol) { EQUALITY[':='].curry[symbol].freeze },
      '==' => ->(symbol) { EQUALITY[':='].curry[symbol].freeze },
      '!=' => ->(symbol) { EQUALITY['!='].curry[symbol].freeze },

      # Comparisons
      '>'  => ->(symbol) { compare_proc(:'>' ).curry[symbol].freeze },
      '>=' => ->(symbol) { compare_proc(:'>=').curry[symbol].freeze },
      '<'  => ->(symbol) { compare_proc(:'<' ).curry[symbol].freeze },
      '<=' => ->(symbol) { compare_proc(:'<=').curry[symbol].freeze },
    }.freeze

    def self.compare?(lhs:, compare:, rhs:)
      # Is the rhs a superclass of lsh, and does rhs respond to the compare method?
      return lhs.public_send(compare, rhs) if lhs.is_a?(rhs.class) && rhs.respond_to?(compare)

      false
    end

    # E.g., > :col, we get comparator: >, args: col
    def self.comparison(comparator:, name:)
      function = COMPARE[comparator]
      Proc.with(type: :symbol, function: function[name])
    end

    def self.matches?(cell)
      match = SYMBOL_COMPARE_RE.match(cell)
      return false unless match

      comparator = match['comparator'] || '='
      name = match['name'].to_sym

      comparison(comparator: comparator, name: name)
    end
  end
end