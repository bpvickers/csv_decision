# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Decision Table that accepts input hashes and makes decisions
  class Table
    # CSVDecision::Columns object - dictionary of all input and output columns
    attr_accessor :columns

    # File path name if decision table loaded from a CSV file
    attr_accessor :file

    # All options used to parse the table
    attr_accessor :options

    # Set if the table row has any output functions (planned feature)
    attr_accessor :outs_functions

    # Data rows - an array of arrays
    attr_accessor :rows

    # Array of CSVDecision::ScanRow objects used to implement matching logic
    attr_accessor :scan_rows

    # Array of CSVDecision::ScanRow objects used to implement outputing final results
    attr_accessor :outs_rows

    # Any array of CSVDecision::Table pre-loaded tables passed to this decision table
    # at load time. Used to allow this decision table to lookup values in other
    # decision tables. (Planned feature.)
    attr_reader :tables

    # Main public method for making decisions.
    #
    # @param input [Hash] - input hash (keys may or may not be symbolized)
    # @return [Hash{Symbol => Object, Array<Object>}] decision
    def decide(input)
      Decide.decide(table: self, input: input, symbolize_keys: true).result
    end

    # Unsafe version of decide - will mutate the hash if set: column type
    # is used (planned feature).
    #
    # @param input [Hash{Symbol => Object}] - input hash (all keys must already be symbolized)
    # @return [Hash{Symbol => Object, Array<Object>}]
    def decide!(input)
      Decide.decide(table: self, input: input, symbolize_keys: false).result
    end

    # Iterate through all data rows of the decision table, with an optional
    # first and last row index given.
    #
    # @param first [Integer] start row
    # @param last [Integer, nil] last row
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
      @outs_rows = []
      @rows = []
      @scan_rows = []
      @tables = nil
    end
  end
end