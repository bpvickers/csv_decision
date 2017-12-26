# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Decision Table that accepts input hashes and makes decisions
  class Table
    # @return [CSVDecision::Columns] Dictionary of all input and output columns.
    attr_accessor :columns

    # @return [File, Pathname, nil] File path name if decision table was loaded from a CSV file.
    attr_accessor :file

    # @return [Hash] All options, explicitly set or defaulted, used to parse the table.
    attr_accessor :options

    # Set if the table row has any output functions (planned feature)
    # attr_accessor :outs_functions

    # @return [Array<Array>] Data rows after parsing.
    attr_accessor :rows

    # @return [Array<CSVDecision::ScanRow>] Scanning objects used to implement input matching logic.
    attr_accessor :scan_rows

    # @return [Array<CSVDecision::ScanRow>] Used to implement outputting of final results.
    attr_accessor :outs_rows

    # @return Array<CSVDecision::Table>] pre-loaded tables passed to this decision table
    #   at load time. Used to allow this decision table to lookup values in other
    #   decision tables. (Planned feature.)
    # attr_reader :tables

    # Main public method for making decisions.
    #
    # @note Input hash keys may or may not be symbolized.
    # @param input [Hash] Input hash.
    # @return [Hash{Symbol => Object, Array<Object>}] Decision hash.
    def decide(input)
      Decide.decide(table: self, input: input, symbolize_keys: true).result
    end

    # Unsafe version of decide - will mutate the hash if +set: column+ type
    # is used (planned feature).
    #
    # @param input (see #decide)
    # @note Input hash must have its keys symbolized.
    # @return (see #decide)
    def decide!(input)
      Decide.decide(table: self, input: input, symbolize_keys: false).result
    end

    # Iterate through all data rows of the decision table, with an optional
    # first and last row index given.
    #
    # @param first [Integer] Start row.
    # @param last [Integer, nil] Last row.
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