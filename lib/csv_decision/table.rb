# frozen_string_literal: true\

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Decision Table that accepts input hashes and makes decision
  class Table
    attr_accessor :file
    attr_accessor :columns
    attr_accessor :options
    attr_accessor :rows
    attr_reader :tables

    def decide(_input, _symbolize_keys: true)
      {}
    end

    def initialize
      @file = nil
      @columns = nil
      @options = nil
      @rows = []
      @tables = nil
    end
  end
end