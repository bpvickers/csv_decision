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
      @result = {}

      # Relevant table attributes
      @first_match = table.options[:first_match]
      @outs = table.columns.outs
      @outs_functions = table.outs_functions

      # Partial result always includes the input hash for calculating output functions
      @partial_result = input[:hash].dup if @outs_functions

      @rows_picked = []
    end

    # Calculate the final result.
    # @return [nil, Hash{Symbol=>Object}] Final result hash if found, otherwise nil for no result.
    def result
      return {} if @rows_picked.blank?
      @first_match ? final_result : accumulated_result
    end

    # Scan the decision table up against the input hash.
    #
    # @param table [CSVDecision::Table] Decision table being processed.
    # @param input (see #initialize)
    # @return [self] Decision object built so far.
    def scan(table:, input:)
      table.each do |row, index|
        return result if row_scan(input: input, row: row, scan_row: table.scan_rows[index])
      end

      result
    end

    private

    def row_scan(input:, row:, scan_row:)
      add(row) if Decide.matches?(row: row, input: input, scan_row: scan_row)
    end

    # Add a matched row to the decision object being built.
    #
    # @param row [Array]
    def add(row)
      return add_first_match(row) if @first_match

      # Accumulate output rows
      @rows_picked << row
      @outs.each_pair { |col, column| accumulate_outs(column_name: column.name, cell: row[col]) }

      # Not done
      false
    end

    def accumulated_result
      return final_result unless @outs_functions
      return eval_outs(@rows_picked.first) unless @multi_result

      multi_row_result
    end

    def multi_row_result
      # Scan each output column that contains functions
      @outs.each_pair do |col, column|
        # Does this column have any functions defined?
        next unless column.eval

        eval_column_procs(col, column)
      end

      final_result
    end

    def accumulate_outs(column_name:, cell:)
      case (current = @result[column_name])
      when nil
        @result[column_name] = cell

      when Array
        @result[column_name] << cell

      else
        @result[column_name] = [current, cell]
        @multi_result ||= true
      end
    end

    def eval_column_procs(col, column)
      @rows_picked.each_with_index do |row, index|
        proc = row[col]
        next unless proc.is_a?(Matchers::Proc)

        # Update the partial result calculated so far and call the function
        value = proc.function[partial_result(index)]
        @multi_result ? @result[column.name][index] = value : @result[column.name] = value
      end
    end

    def partial_result(index)
      @result.each_pair do |column_name, value|
        # Delete this column from the partial result in case there is data from a prior result row
        next @partial_result.delete(column_name) if value[index].is_a?(Matchers::Proc)
        @partial_result[column_name] = value[index]
      end

      @partial_result
    end

    def final_result
      @result
    end

    def add_first_match(row)
      @rows_picked = row

      return eval_outs(row) if @outs_functions

      # Common case is just copying output column values to the final result
      @outs.each_pair { |col, column| @result[column.name] = row[col] }
    end

    def eval_outs(row)
      # Set the constants first, in case the functions refer to them
      eval_outs_constants(row)

      # Then evaluate the functions, left to right
      eval_outs_procs(row)

      final_result
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