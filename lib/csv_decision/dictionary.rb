# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the CSV file's header row. These methods are only required at table load time.
  # @api private
  module Dictionary
    # Table used to build a column dictionary entry.
    ENTRY = {
      in:         { type: :in,    eval: nil },
      'in/text':  { type: :in,    eval: false },
      out:        { type: :out,   eval: nil },
      'out/text': { type: :out,   eval: false },
      guard:      { type: :guard, eval: true },
      if:         { type: :if,    eval: true }
    }.freeze
    private_constant :ENTRY

    # Value object to hold column dictionary entries.
    Entry = Struct.new(:name, :eval, :type) do
      def ins?
        %i[in guard].member?(type) ? true : false
      end
    end

    # These column types do not need a name.
    COLUMN_TYPE_ANONYMOUS = Set.new(%i[guard if]).freeze
    private_constant :COLUMN_TYPE_ANONYMOUS

    # Classify and build a dictionary of all input and output columns by
    # parsing the header row.
    #
    # @param header [Array<String>] The header row after removing any empty columns.
    # @return [Hash<Hash>] Column dictionary is a hash of hashes.
    def self.build(header:, dictionary:)
      header.each_with_index do |cell, index|
        dictionary = parse_cell(cell: cell, index: index, dictionary: dictionary)
      end

      dictionary
    end

    # Add a new symbol to the dictionary of named input and output columns.
    #
    # @param columns [{Symbol=>Symbol}] Hash of column names with key values :in or :out.
    # @param name [Symbol] Symbolized column name.
    # @param out [false, Index] False if an input column, otherwise the index of the output column.
    # @return [{Symbol=>Symbol}] Column dictionary updated with the new name.
    def self.add_name(columns:, name:, out: false)
      Validate.name(columns: columns, name: name, out: out)

      columns[name] = out ? out : :in
      columns
    end

    # Returns the normalized column type, along with an indication if
    # the column requires evaluation
    def self.column_type(column_name, entry)
      Entry.new(column_name, entry[:eval], entry[:type])
    end
    private_class_method :column_type

    def self.parse_cell(cell:, index:, dictionary:)
      column_type, column_name = Validate.column(cell: cell, index: index)

      entry = column_type(column_name, ENTRY[column_type])

      dictionary_entry(dictionary: dictionary, entry: entry, index: index)
    end
    private_class_method :parse_cell

    def self.dictionary_entry(dictionary:, entry:, index:)
      case entry.type
      # A guard column is still added to the ins hash for parsing as an input column.
      when :in, :guard, :set, :'set/nil?', :'set/blank?'
        input_entry(dictionary: dictionary, entry: entry, index: index)

      when :out, :if
        output_entry(dictionary: dictionary, entry: entry, index: index)
      end
    end
    private_class_method :dictionary_entry

    def self.output_entry(dictionary:, entry:, index:)
      case entry.type
      when :if
        dictionary.ifs[index] = entry
      when :out
        add_name(columns: dictionary.columns, name: entry.name, out: index)
      end

      dictionary.outs[index] = entry
      dictionary
    end

    def self.input_entry(dictionary:, entry:, index:)
      case entry.type
      when :in
        add_name(columns: dictionary.columns, name: entry.name)

      when :set, :'set/nil?', :'set/blank?'
        defaults_entry(dictionary: dictionary, entry: entry, index: index)
      end

      dictionary.ins[index] = entry
      dictionary
    end

    def self.defaults_entry(dictionary:, entry:, index:)
      # Default function will set the input value unconditionally or conditionally.
      dictionary.defaults[index] =
        Columns::Default.new(entry.name, nil, default_if(entry.type))
    end

    def self.default_if(type)
      return nil if type == :set
      return :nil? if type == :'set/nil'
      :blank?
    end
    private_class_method :default_if
  end
end