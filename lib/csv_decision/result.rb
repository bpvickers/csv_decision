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
    def initialize(table)
      @outs = table.columns.outs
      @attributes = {}
    end

    # @param key [Symbol, Integer] Key to be deleted from the result.
    # @return [Hash] Attributes hash.
    def delete(key)
      @attributes.delete(key)
    end

    # @param key [Symbol, Index] Access the value in the result for this column name
    def [](column_name)
      @attributes[column_name]
    end

    def []=(column_name, value)
      attributes[column_name] = value
    end

    def add_outs(row)
      # Common case is just copying output column values to the final result
      @outs.each_pair { |col, column| @attributes[column.name] = row[col] }
    end

    def accumulate_outs(row)
      @outs.each_pair { |col, column| accumulate_cell(column_name: column.name, cell: row[col]) }
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

    def eval_outs_constants(row:, partial_result:)
      @outs.each_pair do |col, column|
        value = row[col]
        next if value.is_a?(Matchers::Proc)

        partial_result[column.name] = value
        @attributes[column.name] = value
      end

      partial_result
    end

    def eval_outs_procs(row:, partial_result:)
      @outs.each_pair do |col, column|
        proc = row[col]
        next unless proc.is_a?(Matchers::Proc)

        value = proc.function[partial_result]

        partial_result[column.name] = value
        @attributes[column.name] = value
      end

      partial_result
    end
  end
end