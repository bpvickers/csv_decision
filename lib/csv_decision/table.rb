# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Decision table that accepts an input hash and outputs a decision (hash).
  class Table
    # Make a decision based off an input hash.
    #
    # @note Input hash keys may or may not be symbolized.
    # @param input [Hash] Input hash.
    # @return [{Symbol => Object, Array<Object>}] Decision hash.
    def decide(input)
      Decide.decide(table: self, input: input, symbolize_keys: true)
    end

    # Unsafe version of decide - may mutate the input hash and assumes the input
    # hash is symbolized.
    #
    # @param input (see #decide)
    # @note Input hash must have its keys symbolized.
    #   Input hash will be mutated by any functions that have side effects.
    # @return (see #decide)
    def decide!(input)
      Decide.decide(table: self, input: input, symbolize_keys: false)
    end

    # @return [CSVDecision::Columns] Dictionary of all input and output columns.
    attr_accessor :columns

    # @return [File, Pathname, nil] File path name if decision table was loaded from a CSV file.
    attr_accessor :file

    # @return [CSVDecision::Index] The index built on one or more input columns.
    attr_accessor :index

    # @return [Hash] All options, explicitly set or defaulted, used to parse the table.
    attr_accessor :options

    # Set if the table row has any output functions (planned feature)
    # @api private
    attr_accessor :outs_functions

    # @return [Array<Array>] Data rows after parsing.
    # @api private
    attr_accessor :rows

    # @return [Array<CSVDecision::ScanRow>] Scanning objects used to implement input
    #   matching logic.
    # @api private
    attr_accessor :scan_rows

    # @return [Array<CSVDecision::ScanRow>] Used to implement outputting of final results.
    # @api private
    attr_accessor :outs_rows

    # @return [Array<CSVDecision::ScanRow>] Used to implement filtering of final results.
    # @api private
    attr_accessor :if_rows

    # Iterate through all data rows of the decision table, with an optional
    # first and last row index given.
    #
    # @param first [Integer] Start row.
    # @param last [Integer, nil] Last row.
    # @api private
    def each(first = 0, last = @rows.count - 1)
      index = first
      while index <= last
        yield(@rows[index], index)

        index += 1
      end
    end

    # @api private
    def initialize
      @columns = nil
      @file = nil
      @index = nil
      @options = nil
      @outs_functions = nil
      @outs_rows = []
      @if_rows = []
      @rows = []
      @scan_rows = []
      # @tables = nil
    end
  end
end