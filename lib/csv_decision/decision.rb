# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Accumulate the matching row(s) and calculate the final result.
  # @api private
  class Decision
    # @param table [CSVDecision::Table] Decision table being processed.
    # @param input [Hash{Symbol=>Object}] Input hash data structure.
    def initialize(table:, input:)
      # The result object is a hash of values, and each value will be an array if this is
      # a multi-row result for the +first_match: false+ option.
      @result = Result.new(table: table, input: input)

      # All rows picked by the matching process. An array if +first_match: false+, otherwise
      # a single row.
      @rows_picked = []

      # Relevant table attributes
      table_attributes(table)
    end

    # Scan the decision table up against the input hash.
    #
    # @param (see #initialize)
    # @return [{Symbol=>Object}] Decision result.
    def scan(table:, input:)
      table.each do |row, index|
        # +row_scan+ returns false if more rows need to be scanned, truthy otherwise.
        return result if row_scan(input: input, row: row, scan_row: table.scan_rows[index])
      end

      result
    end

    private

    # Record the relevant table attributes.
    def table_attributes(table)
      @first_match = table.options[:first_match]
      @outs = table.columns.outs
      @outs_functions = table.outs_functions
    end

    # Derive the final result.
    #
    # @return [nil, Hash{Symbol=>Object}] Final result hash if matches found,
    #   otherwise the empty hash for no result.
    def result
      return {} if @rows_picked.blank?
      @first_match ? @result.attributes : accumulated_result
    end

    # Scan the row for matches against the input conditions.
    def row_scan(input:, row:, scan_row:)
      # +add+ returns false if more rows need to be scanned, truthy otherwise.
      add(row) if Decide.matches?(row: row, input: input, scan_row: scan_row)
    end

    # Add a matched row to the decision object being built.
    #
    # @param row [Array] Data row.
    # @return [false, Hash]
    def add(row)
      return add_first_match(row) if @first_match

      # Accumulate output rows
      @rows_picked << row
      @result.accumulate_outs(row)

      # Not done
      false
    end

    def accumulated_result
      return @result.final unless @outs_functions
      return @result.eval_outs(@rows_picked.first) unless @result.multi_result

      multi_row_result
    end

    def multi_row_result
      # Scan each output column that contains functions
      @outs.each_pair { |col, column| eval_column_procs(col: col, column: column) if column.eval }

      @result.final
    end

    def eval_column_procs(col:, column:)
      @rows_picked.each_with_index do |row, index|
        proc = row[col]
        next unless proc.is_a?(Matchers::Proc)

        # Evaluate the proc and update the result
        @result.eval_cell_proc(proc: proc, column_name: column.name, index: index)
      end
    end

    def add_first_match(row)
      # This decision row may contain procs, which if present will need to be evaluated.
      # If this row contains if: columns then this row may be filtered out, in which case
      #
      return eval_single_row(row) if @outs_functions

      # Common case is just copying output column values to the final result.
      @rows_picked = row
      @result.add_outs(row)
    end

    def eval_single_row(row)
      return false unless (result = @result.eval_outs(row))

      @rows_picked = row
      result
    end
  end
end