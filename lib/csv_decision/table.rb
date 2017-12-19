# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Decision Table that accepts input hashes and makes decision
  class Table
    attr_accessor :columns
    attr_accessor :file
    attr_accessor :matchers
    attr_accessor :options
    attr_accessor :outs_functions
    attr_accessor :rows
    attr_accessor :scan_rows
    attr_reader :tables

    def decide(input, _symbolize_keys: true)
      Decide.decide(table: self, input: input, symbolize_keys: false).result
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