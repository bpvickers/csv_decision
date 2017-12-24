# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods dealing wiht column symbols in cells
  module Symbol
    # These procs compare one input hash value to another, and so do not coerce
    EQUALITY = {
      ':=' => proc { |sym, value, hash| value == hash[sym] },
      '!=' => proc { |sym, value, hash| value != hash[sym] }
    }.freeze

    def self.symbol_proc(compare)
      proc { |sym, value, hash| compare?(lhs: value, compare: compare, rhs: hash[sym]) }
    end

    COMPARE = {
      ':=' => ->(symbol) { EQUALITY[':='].curry[symbol].freeze },
      '='  => ->(symbol) { EQUALITY[':='].curry[symbol].freeze },
      '==' => ->(symbol) { EQUALITY[':='].curry[symbol].freeze },
      '!=' => ->(symbol) { EQUALITY['!='].curry[symbol].freeze },

      # Comparisons
      '>'  => ->(symbol) { symbol_proc(:'>' ).curry[symbol].freeze },
      '>=' => ->(symbol) { symbol_proc(:'>=').curry[symbol].freeze },
      '<'  => ->(symbol) { symbol_proc(:'<' ).curry[symbol].freeze },
      '<=' => ->(symbol) { symbol_proc(:'<=').curry[symbol].freeze },
    }.freeze

    REFERENCE = {
      ':'  => ->(symbol) { EQUALITY[':=' ].curry[symbol].freeze },
      '!:' => ->(symbol) { EQUALITY['!='].curry[symbol].freeze }
    }.freeze

    def self.compare?(lhs:, compare:, rhs:)
      return lhs.send(compare, rhs) if lhs.is_a?(rhs.class) && rhs.respond_to?(compare)

      false
    end

    def self.function?(operator:, name:, args:)
      # Do we have just a symbol/column name? - e.g., :column_name
      function = name?(operator: operator, name: name, args: args)
      return function if function

      # Do we have a column name expression such as > :col or == :col
      return comparison?(comparator: operator, args: args) if name == :':'

      false
    end

    # E.g., > :col, we get comparator: >, args: col
    def self.comparison?(comparator:, args:)
      return false if args.empty?

      function = COMPARE[comparator]
      Proc.with(type: :symbol, function: function[args.to_sym])
    end

    def self.name?(operator:, name:, args:)
      #   Do we have an expression starting with a symbol name - e.g, :col
      # or it's negation - e.g., !:col
      return false unless args.empty?
      return false unless (function = REFERENCE[operator])

      Proc.with(type: :symbol, function: function[name])
    end
  end
end