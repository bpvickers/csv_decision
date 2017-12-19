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
      @outs_functions = table.outs_functions

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

    def add(row)
      return add_first_match(row) if @first_match

      # Accumulate output rows
      @rows_picked << row
    end

    def result
      return {} if empty?
      return final_result unless @outs_functions

      nil
    end

    private

    def final_result
      @result
    end

    def add_first_match(row)
      @row_picked = row

      # Common case if just copying output column values to the final result
      @outs.each_pair { |col, column| @result[column[:name]] = row[col] }
    end
  end
end