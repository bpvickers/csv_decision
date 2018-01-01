# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Accumulate the matching row(s).
  # @api private
  class Result
    attr_reader :attributes
    attr_reader :multi_result

    # @yieldparam column_name [Symbol, Index] The result column name.
    # @yieldparam value [Object] The value for the column name, which may be an array.
    def each_pair
      @attributes.each_pair do |column_name, value|
        yield(column_name, value)
      end
    end

    # @param table [CSVDecision::Table] Decision table being processed.
    def initialize(table:, input:)
      @outs = table.columns.outs
      @if_columns = table.columns.ifs

      # Partial result always includes the input hash for calculating output functions
      @partial_result = input[:hash].dup if table.outs_functions

      @attributes = {}
    end

    def add_outs(row)
      # Common case is just copying output column values to the final result
      @outs.each_pair { |col, column| @attributes[column.name] = row[col] }
    end

    def accumulate_outs(row)
      @outs.each_pair { |col, column| accumulate_cell(column_name: column.name, cell: row[col]) }
    end

    def final
      return @attributes if @if_columns.empty?

      return single_row_result unless @multi_result
      multi_row_result
    end

    def multi_row_result
      @if_columns.each_key { |col| check_if_column(col) }
      #   @attributes[col].each_with_index { |value, index| delete_rows << index unless value }
      #
      #   # Remove the if: column from the final result
      #   @attributes.delete(col)
      #
      #   # Adjust row index as we delete rows
      #   delete_rows.each_with_index { |index, sequence| delete_row(index - sequence) }
      # end

      normalize
    end

    def check_if_column(col)
      delete_rows = []
      @attributes[col].each_with_index { |value, index| delete_rows << index unless value }

      # Remove this if: column from the final result
      @attributes.delete(col)

      # Adjust the row index as we delete rows in sequence.
      delete_rows.each_with_index { |index, sequence| delete_row(index - sequence) }
    end

    def normalize
      value = @attributes.values.first
      # If it's still multi-row return as is.
      return @attributes if value.count > 1

      # If all rows have been deleted return the empty hash.
      return {} if value.count.zero?

      # We have a single row, so turn single row arrays into constants
      @attributes.transform_values!(&:first)
    end

    def delete_row(index)
      @attributes.transform_values { |value| value.delete_at(index) }
    end

    # Case where we have a single row result
    def single_row_result
      @if_columns.each_key do |col|
        return nil unless @attributes[col]

        # Remove the if: column from the final result
        @attributes.delete(col)
      end

      @attributes
    end

    def eval_outs(row)
      # Set the constants first, in case the functions refer to them
      @partial_result = eval_outs_constants(row: row)

      # Then evaluate the functions, left to right
      eval_outs_procs(row: row)

      final
    end

    def eval_cell_proc(proc:, column_name:, index:)
      @partial_result = partial(index: index)
      value = proc.function[@partial_result]
      @attributes[column_name][index] = value
    end

    private

    def eval_outs_constants(row:)
      @outs.each_pair do |col, column|
        value = row[col]
        next if value.is_a?(Matchers::Proc)

        @partial_result[column.name] = value
        @attributes[column.name] = value
      end

      @partial_result
    end

    def partial(index:)
      @attributes.each_pair do |column_name, value|
        # Delete this column from the partial result in case there is data from a prior result row
        next @partial_result.delete(column_name) if value[index].is_a?(Matchers::Proc)

        # Add this constant value to the partial result row built so far.
        @partial_result[column_name] = value[index]
      end

      @partial_result
    end

    def eval_outs_procs(row:)
      @outs.each_pair do |col, column|
        proc = row[col]
        next unless proc.is_a?(Matchers::Proc)

        value = proc.function[@partial_result]

        @partial_result[column.name] = value
        @attributes[column.name] = value
      end

      @partial_result
    end

    def accumulate_cell(column_name:, cell:)
      case (current = @attributes[column_name])
      when nil
        @attributes[column_name] = cell

      when Array
        @attributes[column_name] << cell

      else
        @attributes[column_name] = [current, cell]
        @multi_result ||= true
      end
    end
  end
end