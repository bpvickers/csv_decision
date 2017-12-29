# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Accumulate the matching row(s) and calculate the final result
  class Decision
    # Match the table row against the input hash.
    #
    # @param row [Array] Table row.
    # @param input [Hash{Symbol=>Object}] Input hash data structure.
    # @param scan_row [ScanRow]
    # @return [Boolean] Returns true if a match, false otherwise.
    def self.matches?(row:, input:, scan_row:)
      match = scan_row.match_constants?(row: row, scan_cols: input[:scan_cols])
      return false unless match

      return true if scan_row.procs.empty?

      scan_row.match_procs?(row: row, input: input)
    end

    # @param table [CSVDecision::Table] Decision table being processed.
    # @param input [Hash{Symbol=>Object}] Input hash data structure.
    def initialize(table:, input:)
      @result = {}

      # Relevant table attributes
      @first_match = table.options[:first_match]
      @outs = table.columns.outs
      @outs_functions = table.outs_functions
      @outs_rows = table.outs_rows

      # Partial result always includes the input hash for calculating output functions
      @partial_result = input[:hash].dup if @outs_functions

      @row_picked = nil
      return if @first_match

      # Extra attributes for the accumulate option
      @rows_picked = []
      @multi_result = nil
    end

    # Is the result set empty? That is, nothing matched?
    # @return [Boolean] True if no result, false otherwise.
    def empty?
      return @row_picked.nil? if @first_match
      @rows_picked.empty?
    end

    # Does the result exist?
    # @return [Boolean] True if result exists, false otherwise.
    def exist?
      !empty?
    end

    # Calculate the final result.
    # @return [nil, Hash{Symbol=>Object}] Final result hash if found, otherwise nil for no result.
    def result
      return {} if empty?
      return final_result if @first_match

      accumulated_result
    end

    # TODO: stub
    def accumulated_result
      return final_result unless @outs_functions

      raise 'accumulate option does not support functions'
    end

    # Scan the decision table up against the input hash.
    #
    # @param table [CSVDecision::Table] Decision table being processed.
    # @param input (see #initialize)
    # @return [self] Decision object built so far.
    def scan(table:, input:)
      scan_rows = table.scan_rows

      table.each do |row, index|
        done = row_scan(input: input, row: row, scan_row: scan_rows[index])

        return self if done
      end

      self
    end

    private

    # Add a matched row to the decision object being built.
    #
    # @param row [Array]
    def add(row)
      return add_first_match(row) if @first_match

      # Accumulate output rows
      @rows_picked << row
      @outs.each_pair do |col, column|
        accumulate_outs(column_name: column.name, cell: row[col])
      end

      # Not done
      false
    end

    def accumulate_outs(column_name:, cell:)
      current = @result[column_name]

      case current
      when nil
        @result[column_name] = cell

      when Array
        @result[column_name] << cell

      else
        @result[column_name] = [current, cell]
        @multi_result ||= true
      end
    end

    def row_scan(input:, row:, scan_row:)
      return unless Decision.matches?(row: row, input: input, scan_row: scan_row)

      add(row)
    end

    def final_result
      @result
    end

    def add_first_match(row)
      @row_picked = row

      return eval_outs(row) if @outs_functions

      # Common case is just copying output column values to the final result
      @outs.each_pair { |col, column| @result[column.name] = row[col] }
    end

    def eval_outs(row)
      # Set the constants first, in case the functions refer to them
      eval_outs_constants(row)

      # Then evaluate the functions, left to right
      eval_outs_procs(row)
    end

    def eval_outs_constants(row)
      @outs.each_pair do |col, column|
        value = row[col]
        next if value.is_a?(Matchers::Proc)

        @partial_result[column.name] = value
        @result[column.name] = value
      end
    end

    def eval_outs_procs(row)
      @outs.each_pair do |col, column|
        proc = row[col]
        next unless proc.is_a?(Matchers::Proc)

        value = proc.function[@partial_result]

        @partial_result[column.name] = value
        @result[column.name] = value
      end
    end
  end
end