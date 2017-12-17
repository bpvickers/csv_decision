# frozen_string_literal: true\

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Decision Table that accepts input hashes and makes deciosn
  class Table
    attr_accessor :rows
    attr_accessor :options
    attr_reader :file

    def decide(input, symbolize_keys: true)
      {}
    end

    def initialize
      @options = nil
      @rows = []
      @file = nil
      @tables = nil
    end
  end
end