# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Decision Table that accepts input hashes and makes decision
  class Table
    attr_accessor :columns
    attr_accessor :file
    attr_accessor :options
    attr_accessor :outs_functions
    attr_accessor :rows
    attr_accessor :scan_rows
    attr_reader :tables

    # Main public method for making decisions.
    # @param input [Hash] - input hash (keys may or may not be symbolized)
    # @return [Hash]
    def decide(input)
      Decide.decide(table: self, input: input, symbolize_keys: true).result
    end

    # Unsafe version of decide - will mutate the hash if set: option (planned feature)
    # is used.
    # @param input [Hash] - input hash (keys must be symbolized)
    # @return [Hash]
    def decide!(input)
      Decide.decide(table: self, input: input, symbolize_keys: false).result
    end

    # Iterate through all data rows of the decision table.
    # @param first [Integer] - start row
    # @param last [Integer] - last row
    def each(first = 0, last = @rows.count - 1)
      index = first
      while index <= (last || first)
        yield(@rows[index], index)

        index += 1
      end
    end

    def initialize
      @columns = nil
      @file = nil
      @matchers = []
      @options = nil
      @outs_functions = nil
      @rows = []
      @scan_rows = []
      @tables = nil
    end
  end
end