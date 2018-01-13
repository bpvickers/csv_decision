# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Accumulate the matching row(s) into a result hash.
  # @api private
  class Result
    # @return [Hash{Symbol=>Object}, Hash{Integer=>Object}] The decision result hash containing
    #   both result values and if: columns, which eventually get evaluated and removed.
    attr_reader :attributes

    attr_reader :outs

    attr_reader :outs_functions

    # @return [Boolean] Returns true if this is a multi-row result
    attr_reader :multi_result

    # (see Decision.initialize)
    def initialize(table:, input:)
      @outs = table.columns.outs
      @outs_functions = table.outs_functions
      @if_columns = table.columns.ifs

      # Partial result always copies in the input hash for calculating output functions.
      # Note that these input key values will not be mutated, as output columns can never
      # have the same symbol as an input hash key.
      # However, the rest of this hash is mutated as output column evaluation results
      # are accumulated.
      @partial_result = input&.slice(*table.columns.input_keys) if @outs_functions

      # Attributes hash contains the output decision key value pairs
      @attributes = {}

      # Set to true if the result has more than one row.
      # Only possible for the first_match: false option.
      @multi_result = false
    end

    # Common case for building a single row result is just copying output column values to the
    # final result hash.
    # @param row [Array]
    # @return [void]
    def add_outs(row)
      @outs.each_pair { |col, column| @attributes[column.name] = row[col] }
    end

    # Accumulate the outs into arrays of values.
    # @param row [Array]
    # @return [void]
    def accumulate_outs(row)
      @outs.each_pair { |col, column| add_cell(column_name: column.name, cell: row[col]) }
    end

    # Derive the final result.
    # @return [{Symbol=>Object}]
    def final
      # If there are no if: columns, then nothing needs to be filtered out of this result hash.
      return @attributes if @if_columns.empty?

      @multi_result ? multi_row_result : single_row_result
    end

    # Evaluate the output columns, and use them to start building the final result,
    # along with the partial result required to evaluate functions.
    #
    # @param row [Array]
    # @return (see #final)
    def eval_outs(row)
      # Set the constants first, in case the functions refer to them
      eval_outs_constants(row: row)

      # Then evaluate the procs, left to right
      eval_outs_procs(row: row)

      final
    end

    # Evaluate the cell proc using the partial result calculated so far.
    #
    # @param proc [Matchers::Pro]
    # @param column_name [Symbol, Integer]
    # @param index [Integer]
    def eval_cell_proc(proc:, column_name:, index:)
      @attributes[column_name][index] = proc.function[partial_result(index)]
    end

    private

    # Case where we have a single row result, which either gets returned
    # or filtered by the if: column conditions.
    def single_row_result
      @if_columns.each_key do |col|
        return nil unless @attributes[col]

        # Remove the if: column from the final result hash.
        @attributes.delete(col)
      end

      @attributes
    end

    def multi_row_result
      @if_columns.each_key { |col| check_if_column(col) }

      normalize_result
    end

    def check_if_column(col)
      delete_rows = []
      @attributes[col].each_with_index { |value, index| delete_rows << index unless value }

      # Remove this if: column from the final result
      @attributes.delete(col)

      # Adjust the row index as we delete rows in sequence.
      delete_rows.each_with_index { |index, sequence| delete_row(index - sequence) }
    end

    # Each result "row", given by the row +index+ is a collection of column arrays.
    # @param index [Integer] Row index.
    # @return [{Symbol=>Object}, {Integer=>Object}]
    def delete_row(index)
      @attributes.transform_values { |value| value.delete_at(index) }
    end

    # @return [{Symbol=>Object}] Decision result hash with any if: columns removed.
    def normalize_result
      # Peek at the first column's result and see how many rows it contains.
      count = @attributes.values.first.count
      @multi_result = count > 1

      case count
      when 0
        {}

      # Single row array values do not require arrays.
      when 1
        @attributes.transform_values!(&:first)

      else
        @attributes
      end
    end

    def eval_outs_constants(row:)
      @outs.each_pair do |col, column|
        value = row[col]
        next if value.is_a?(Matchers::Proc)

        @partial_result[column.name] = value
        @attributes[column.name] = value
      end
    end

    def eval_outs_procs(row:)
      @outs.each_pair do |col, column|
        proc = row[col]
        next unless proc.is_a?(Matchers::Proc)

        value = proc.function[@partial_result]

        @partial_result[column.name] = value
        @attributes[column.name] = value
      end
    end

    def partial_result(index)
      @attributes.each_pair do |column_name, value|
        # Delete this column from the partial result in case there is data from a prior result row
        next @partial_result.delete(column_name) if value[index].is_a?(Matchers::Proc)

        # Add this constant value to the partial result row built so far.
        @partial_result[column_name] = value[index]
      end

      @partial_result
    end

    def add_cell(column_name:, cell:)
      case (current = @attributes[column_name])
      when nil
        @attributes[column_name] = cell

      when Matchers::Proc
        @attributes[column_name] = [current, cell]
        @multi_result = true

      when Array
        @attributes[column_name] << cell

      else
        @attributes[column_name] = [current, cell]
        @multi_result = true
      end
    end
  end
end