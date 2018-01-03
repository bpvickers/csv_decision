# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Dictionary of all this table's columns - inputs, outputs etc.
  # @api private
  class Columns
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

      # if: columns.
      # @return [Hash{Integer=>Entry}] All if: column dictionary entries.
      attr_accessor :ifs

      # TODO: Input hash path - optional (planned feature)
      # attr_accessor :path

      # TODO: Input columns with a default value (planned feature)
      # attr_accessor :defaults

      def initialize
        @ins = {}
        @outs = {}
        @ifs = {}
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

    # if: columns hash keyed by column index.
    # @return [Hash{Index=>Entry}]
    def ifs
      @dictionary.ifs
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
      @dictionary = CSVDecision::Dictionary.build(row: row, dictionary: Dictionary.new) if row

      freeze
    end
  end
end