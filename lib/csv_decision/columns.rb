# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Dictionary of all this table's columns - inputs, outputs etc.
  class Columns
    # Value object to hold column dictionary entries.
    Entry = Struct.new(:name, :eval, :type) do
      def ins?
        %i[in guard].member?(type) ? true : false
      end
    end

    # TODO: Value object used for any columns with defaults
    # Default = Struct.new(:name, :function, :default_if)

    # Dictionary of all data columns.
    # The key of each hash is the header cell's array column index.
    # Note that input and output columns can be interspersed and need not have unique names.
    class Dictionary
      # Input columns.
      # @return [Hash{Integer=>Entry}] All input column dictionary entries.
      attr_accessor :ins

      # Output columns.
      # @return [Hash{Integer=>Entry}] All output column dictionary entries.
      attr_accessor :outs

      # TODO: Input hash path - optional (planned feature)
      # attr_accessor :path

      # TODO: Input columns with a default value (planned feature)
      # attr_accessor :defaults

      def initialize
        @ins = {}
        @outs = {}
        # TODO: @path = {}
        # TODO: @defaults = {}
      end
    end

    # Dictionary of all data columns.
    # @return [Columns::Dictionary]
    attr_reader :dictionary

    # Input columns hash keyed by column index.
    # @return [Hash{Index=>Entry}]
    def ins
      @dictionary.ins
    end

    # Output columns hash keyed by column index.
    # @return [Hash{Index=>Entry}]
    def outs
      @dictionary.outs
    end

    # Input columns with defaults specified (planned feature)
    # def defaults
    #   @dictionary.defaults
    # end

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
      @dictionary = Header.dictionary(row: row) if row

      freeze
    end
  end
end