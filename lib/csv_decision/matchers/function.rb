# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to assign a matcher to data cells
  # @api private
  class Matchers
    # Match cell against a function call
    #   * no arguments - e.g., := present?
    #   * with arguments - e.g., :=lookup?(:table)
    # TODO: fully implement
    class Function < Matcher
      # Looks like a function call or symbol expressions, e.g.,
      # == true
      # := function(arg: symbol)
      # == :column_name
      FUNCTION_CALL =
        "(?<operator>=|:=|==|=|<|>|!=|>=|<=|:|!\\s*:)\\s*" \
        "(?<negate>!?)\\s*" \
        "(?<name>#{Header::COLUMN_NAME}|:)(?<args>.*)"
      private_constant :FUNCTION_CALL

      # Function call regular expression.
      FUNCTION_RE = Matchers.regexp(FUNCTION_CALL)

      def self.matches?(cell)
        match = FUNCTION_RE.match(cell)
        return false unless match

        # operator = match['operator']&.gsub(/\s+/, '')
        # name = match['name'].to_sym
        # args = match['args'].strip
        # negate = match['negate'] == Matchers::NEGATE
      end

      # @param options (see Parse.parse)
      def initialize(options = {})
        @options = options
      end

      # @param (see Matchers::Matcher#matches?)
      # @return (see Matchers::Matcher#matches?)
      def matches?(cell, _path = [])
        Function.matches?(cell)
      end

      # (see Matcher#outs?)
      # def outs?
      #   true
      # end
    end
  end
end