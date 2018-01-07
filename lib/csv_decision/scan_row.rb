# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Data row object indicating which columns are constants versus procs.
  # @api private
  class ScanRow
    # These column types cannot have constants in their data cells.
    NO_CONSTANTS = Set.new(%i[guard if]).freeze
    private_constant :NO_CONSTANTS

    # Scan the table cell against all matches.
    #
    # @param matchers [Array<Matchers::Matcher>]
    # @param cell [String]
    # @return [false, Matchers::Proc]
    def self.scan(column:, matchers:, cell:)
      return false if cell == ''

      proc = scan_matchers(column: column, matchers: matchers, cell: cell)
      return proc if proc

      # Must be a simple string constant - this is OK except for a certain column types.
      invalid_constant?(type: :constant, column: column)
    end

    def self.scan_matchers(column:, matchers:, cell:)
      matchers.each do |matcher|
        # Guard function only accepts the same matchers as an output column.
        next if guard_ins_matcher?(column, matcher)

        proc = scan_proc(column: column, cell: cell, matcher: matcher)
        return proc if proc
      end

      # Must be a string constant
      false
    end
    private_class_method :scan_matchers

    # A guard column can only use output matchers
    def self.guard_ins_matcher?(column, matcher)
     !matcher.outs? && column.type == :guard
    end
    private_class_method :guard_ins_matcher?

    def self.scan_proc(column:, cell:, matcher:)
      proc = matcher.matches?(cell)
      invalid_constant?(type: proc.type, column: column) if proc

      proc
    end
    private_class_method :scan_proc

    def self.invalid_constant?(type:, column:)
      return false unless type == :constant && NO_CONSTANTS.member?(column.type)

      raise CellValidationError, "#{column.type}: column cannot contain constants"
    end
    private_class_method :invalid_constant?

    # Evaluate the cell proc against the column's input value and/or input hash.
    #
    # @param proc [CSVDecision::Proc] Proc in the table cell.
    # @param value [Object] Value supplied in the input hash corresponding to this column.
    # @param hash [{Symbol=>Object}] Input hash with symbolized keys.
    def self.eval_matcher(proc:, hash:, value: nil)
      function = proc.function

      # A symbol guard expression just needs to be passed the input hash
      return function[hash] if proc.type == :guard

      # All other procs can take one or two args
      function.arity == 1 ? function[value] : function[value, hash]
    end

    # @return [Array<Integer>] Column indices for simple constants.
    attr_reader :constants

    # @return [Array<Integer>] Column indices for Proc objects.
    attr_reader :procs

    def initialize
      @constants = []
      @procs = []
    end

    # Scan all the specified +columns+ (e.g., inputs) in the given +data+ row using the +matchers+
    # array supplied.
    #
    # @param row [Array<String>] Data row - still just all string constants.
    # @param columns [Array<Columns::Entry>] Array of column dictionary entries.
    # @param matchers [Array<Matchers::Matcher>] Array of table cell matchers.
    # @return [Array] Data row with anything not a string constant replaced with a Proc or a
    #   non-string constant.
    def scan_columns(row:, columns:, matchers:)
      columns.each_pair do |col, column|
        # An empty input cell matches everything, and so never needs to be scanned
        next if (cell = row[col]) == '' && column.ins?

        # If the column is text only then no special matchers need be invoked
        next @constants << col if column.eval == false

        # Need to scan the cell against all matchers, and possibly overwrite
        # the cell contents with a Matchers::Proc.
        row[col] = scan_cell(column: column, col: col, matchers: matchers, cell: cell)
      end

      row
    end

    # Match cells containing simple constants.
    # @param row (see ScanRow.scan_columns)
    # @param scan_cols [Hash{Integer=>Object}]
    # @return [Boolean] True for a match, false otherwise.
    def match_constants?(row:, scan_cols:)
      constants.each do |col|
        return false unless row[col] == scan_cols[col]
      end

      true
    end

    # Match cells containing a Proc object.
    # @param row (see ScanRow.scan_columns)
    # @param input  [Hash{Symbol => Hash{Symbol=>Object}, Hash{Integer=>Object}}]
    # @return [Boolean] True for a match, false otherwise.
    def match_procs?(row:, input:)
      hash = input[:hash]
      scan_cols = input[:scan_cols]

      procs.each do |col|
        match = ScanRow.eval_matcher(proc: row[col], value: scan_cols[col], hash: hash)
        return false unless match
      end

      true
    end

    private

    def scan_cell(column:, col:, matchers:, cell:)
      # Scan the cell against all the matchers
      proc = ScanRow.scan(column: column, matchers: matchers, cell: cell)

      return set(proc, col) if proc

      # Just a plain constant
      @constants << col
      cell
    end

    def set(proc, col)
      # Unbox a constant
      if proc.type == :constant
        @constants << col
        return proc.function
      end

      @procs << col
      proc
    end
  end
end