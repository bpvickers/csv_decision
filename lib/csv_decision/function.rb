# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to recognise various function expressions
  module Function
    # Looks like a function call or symbol expressions, e.g.,
    # == true
    # := function(arg: symbol)
    # == :column_name
    FUNCTION_CALL =
      "(?<operator>=|:=|==|=|<|>|!=|>=|<=|:|!\\s*:)\\s*" \
        "(?<negate>!?)\\s*" \
        "(?<name>#{Header::COLUMN_NAME}|:)(?<args>.*)"

    FUNCTION = Matchers.regexp(FUNCTION_CALL)

    def self.matches?(cell)
      match = FUNCTION.match(cell)
      return false unless match

      operator = match['operator']&.gsub(/\s+/, '')
      name = match['name'].to_sym
      args = match['args'].strip
      negate = match['negate'] == Matchers::NEGATE

      function = Symbol.comparison(comparator: operator, name: name)
      return function if function

      false
    end
  end
end