# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Dictionary of all this table's columns - inputs, outputs etc.
  # @api private
  class Columns
    def self.outs_dictionary(columns:, row:)
      row.each_with_index do |cell, index|
        outs_check_cell(columns: columns, cell: cell, index: index)
      end
    end

    def self.ins_dictionary(columns:, row:)
      row.each { |cell| ins_cell_dictionary(columns: columns, cell: cell) }
    end

    def self.ins_cell_dictionary(columns:, cell:)
      return unless cell.is_a?(Matchers::Proc)
      return if cell.symbols.nil?

      add_ins_symbols(columns: columns, cell: cell)
    end

    def self.outs_check_cell(columns:, cell:, index:)
      return unless cell.is_a?(Matchers::Proc)
      return if cell.symbols.nil?

      check_outs_symbols(columns: columns, cell: cell, index: index)
    end
    private_class_method :outs_check_cell

    def self.check_outs_symbols(columns:, cell:, index:)
      Array(cell.symbols).each do |symbol|
        check_outs_symbol(columns: columns, symbol: symbol, index: index)
      end
    end
    private_class_method :check_outs_symbols

    def self.check_outs_symbol(columns:, symbol:, index:)
      in_out = columns.dictionary[symbol]

      # If its an input column symbol then we're good.
      return if ins_symbol?(columns: columns, symbol: symbol, in_out: in_out)

      # Check if this output symbol reference is on or after this cell's column
      invalid_out_ref?(columns, index, in_out)
    end
    private_class_method :check_outs_symbol

    # If the symbol exists either as an input or does not exist then we're good.
    def self.ins_symbol?(columns:, symbol:, in_out:)
      return true if in_out == :in

      # It must an input symbol, as all the output symbols have been parsed.
      return columns.dictionary[symbol] = :in if in_out.nil?

      false
    end
    private_class_method :ins_symbol?

    def self.invalid_out_ref?(columns, index, in_out)
      return false if in_out < index

      that_column = if in_out == index
                      'reference to itself'
                    else
                      "an out of order reference to output column '#{columns.outs[in_out].name}'"
                    end
      raise CellValidationError,
            "output column '#{columns.outs[index].name}' makes #{that_column}"
    end
    private_class_method :invalid_out_ref?

    def self.add_ins_symbols(columns:, cell:)
      Array(cell.symbols).each do |symbol|
        CSVDecision::Dictionary.add_name(columns: columns, name: symbol)
      end
    end
    private_class_method :add_ins_symbols

    # Dictionary of all table data columns.
    # The key of each hash is the header cell's array column index.
    # Note that input and output columns may be interspersed, and multiple input columns
    # may refer to the same input hash key symbol.
    # However, output columns must have unique symbols, which cannot overlap with input
    # column symbols.
    class Dictionary
      # @return [Hash{Integer=>Entry}] All column names.
      attr_accessor :columns

      # @return [Hash{Integer=>Entry}] All input column dictionary entries.
      attr_accessor :ins

      # @return [Hash{Integer=>Entry}] All defaulted input column dictionary
      #  entries. This is actually just a subset of :ins.
      attr_accessor :defaults

      # @return [Hash{Integer=>Entry}] All output column dictionary entries.
      attr_accessor :outs

      # @return [Hash{Integer=>Entry}] All if: column dictionary entries.
      #   This is actually just a subset of :outs.
      attr_accessor :ifs

      attr_reader :keys

      def initialize(table)
        @columns = {}
        @defaults = {}
        @ifs = {}
        @ins = {}
        @outs = {}
        @keys = table.options[:index]
      end
    end

    # Input columns with defaults specified
    def defaults
      @dictionary&.defaults
    end

    # Set defaults for columns with defaults specified
    def defaults=(value)
      @dictionary.defaults = value
    end

    # @return [Hash{Symbol=>[false, Integer]}] Dictionary of all
    #   input and output column names.
    def dictionary
      @dictionary.columns
    end

    # Input columns hash keyed by column index.
    # @return [Hash{Index=>Entry}]
    def ins
      @dictionary.ins
    end

    # Output columns hash keyed by column index.
    # @return [Hash{Index=>Entry}]
    def outs
      @dictionary&.outs
    end

    # if: columns hash keyed by column index.
    # @return [Hash{Index=>Entry}]
    def ifs
      @dictionary.ifs
    end

    # @return [Array<Symbol>] All input column symbols.
    def input_keys
      @dictionary.columns.select { |_k, v| v == :in }.keys
    end

    # @param table [Table] Decision table being constructed.
    def initialize(table)
      # If a column does not have a valid header cell, then it's empty of data.
      # Return the stripped header row, and remove it from the data array.
      row = Header.strip_empty_columns(rows: table.rows)

      # No header row found?
      raise TableValidationError, 'table has no header row' unless row

      # Build a dictionary of all valid data columns from the header row.
      dictionary =  Dictionary.new(table)
      @dictionary = CSVDecision::Dictionary.build(header: row, dictionary: dictionary)

      freeze
    end
  end
end