# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Accumulate the matching row(s) and calculate the final result
  class Decision
    def initialize(table:, input:)
      @result = {}

      # Relevant table attributes
      @first_match = table.options[:first_match]
      @outs = table.columns.outs

      # TODO: Planned feature
      # @outs_functions = table.outs_functions

      # Partial result always includes the input hash for calculating output functions
      @partial_result = input[:hash].dup if @outs_functions

      @row_picked = nil
      return if @first_match

      # Extra attributes for the accumulate option
      @rows_picked = []
      @multi_result = nil
    end

    # Is the result set empty? That is, nothing matched?
    def empty?
      return @row_picked.nil? if @first_match
      @rows_picked.empty?
    end

    def exist?
      !empty?
    end

    def result
      return {} if empty?
      return final_result unless @outs_functions

      nil
    end

    def scan(table:, input:)
      scan_rows = table.scan_rows

      table.each do |row, index|
        done = row_scan(input: input, row: row, scan_row: scan_rows[index])

        return self if done
      end

      self
    end

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

    private

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
      return unless Decide.matches?(row: row, input: input, scan_row: scan_row)

      add(row)
    end

    def final_result
      @result
    end

    def add_first_match(row)
      @row_picked = row

      # Common case is just copying output column values to the final result
      @outs.each_pair { |col, column| @result[column.name] = row[col] }
    end
  end
end