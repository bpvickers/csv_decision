# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Dictionary of all this table's columns - inputs, outputs etc.
  # @api private
  class Columns
    # Value object used for any columns with defaults.
    Default = Struct.new(:name, :function, :default_if)

    # Dictionary of all data columns.
    # The key of each hash is the header cell's array column index.
    # Note that input and output columns can be interspersed and need not have unique names.
    class Dictionary
      # @return [Hash{Integer=>Entry}] All column names.
      attr_accessor :columns

      # @return [Hash{Integer=>Entry}] All defaulted input column dictionary
      #  entries.
      attr_accessor :defaults

      # @return [Hash{Integer=>Entry}] All input column dictionary entries.
      attr_accessor :ins

      # @return [Hash{Integer=>Entry}] All output column dictionary entries.
      attr_accessor :outs

      # @return [Hash{Integer=>Entry}] All if: column dictionary entries.
      attr_accessor :ifs

      # TODO: Input hash path - optional (planned feature)
      # attr_accessor :path

      def initialize
        @columns = {}
        @defaults = {}
        @ifs = {}
        @ins = {}
        @outs = {}
        # TODO: @path = {}
      end
    end

    # Input columns with defaults specified (planned feature)
    def defaults
      @dictionary.defaults
    end

    # @return [{Symbol=>[false, Integer]}] Dictionary of all
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

    # @return [Array<Symbol] All input column symbols.
    def input_keys
      @dictionary.columns.select { |_k, v| v == :in }.keys
    end

    # Input hash path (planned feature)
    # def path
    #   @dictionary.path
    # end

    # @param table [Table] Decision table being constructed.
    def initialize(table)
      # If a column does not have a valid header cell, then it's empty of data.
      # Return the stripped header row, and remove it from the data array.
      row = Header.strip_empty_columns(rows: table.rows)

      # Build a dictionary of all valid data columns from the header row.
      @dictionary = CSVDecision::Dictionary.build(header: row, dictionary: Dictionary.new) if row

      freeze
    end
  end
end