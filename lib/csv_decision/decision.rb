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
      @first_match = table.options[:first_match]
    end

    # Scan the decision table up against the input hash.
    #
    # @param (see #initialize)
    # @return [{Symbol=>Object}] Decision result.
    def scan(table:, hash:, scan_cols:)
      scan_rows = table.scan_rows

      table.each do |row, index|
        next unless scan_rows[index].match?(row: row, hash: hash, scan_cols: scan_cols)
        return @result.attributes if add(row)
      end

      @rows_picked.empty? ? {} : accumulated_result
    end

    # Use an index to scan the decision table up against the input hash.
    #
    # @param (see #initialize)
    # @return [{Symbol=>Object}] Decision result.
    def index(keys:, table:, hash:, scan_cols:)
      scan_rows = table.scan_rows

      table.each do |row, index|
        next unless scan_rows[index].match?(row: row, hash: hash, scan_cols: scan_cols)
        return @result.attributes if add(row)
      end

      @rows_picked.empty? ? {} : accumulated_result
    end

    private

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
      return @result.final unless @result.outs_functions
      return @result.eval_outs(@rows_picked.first) unless @result.multi_result

      multi_row_result
    end

    def multi_row_result
      # Scan each output column that contains functions
      @result.outs.each_pair { |col, column| eval_procs(col: col, column: column) if column.eval }

      @result.final
    end

    def eval_procs(col:, column:)
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
      # this method call will return false.
      return eval_single_row(row) if @result.outs_functions

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