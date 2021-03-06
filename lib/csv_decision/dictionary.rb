# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the CSV file's header row. These methods are only required at table load time.
  # @api private
  module Dictionary
    # Add a new symbol to the dictionary of named input and output columns.
    #
    # @param columns [{Symbol=>Symbol}] Hash of column names with key values :in or :out.
    # @param name [Symbol] Symbolized column name.
    # @param out [false, Index] False if an input column, otherwise the index of the output column.
    # @return [Hash{Symbol=>[:in, Integer]}] Column dictionary updated with the new name.
    def self.add_name(columns:, name:, out: false)
      Validate.name(columns: columns, name: name, out: out)

      columns[name] = out ? out : :in
      columns
    end

    # Column dictionary entries.
    class Entry
      # Table used to build a column dictionary entry.
      ENTRY = {
        in:           { type: :in,    eval: nil },
        'in/text':    { type: :in,    eval: false },
        set:          { type: :set,   eval: nil, set_if: true },
        'set/nil?':   { type: :set,   eval: nil, set_if: :nil? },
        'set/blank?': { type: :set,   eval: nil, set_if: :blank? },
        out:          { type: :out,   eval: nil },
        'out/text':   { type: :out,   eval: false },
        guard:        { type: :guard, eval: true },
        if:           { type: :if,    eval: true },
        path:         { type: :path,  eval: false }
      }.freeze
      private_constant :ENTRY

      # Input column types.
      INS_TYPES = %i[in guard set].freeze
      private_constant :INS_TYPES

      # Create a new column dictionary entry defaulting attributes from the column type,
      # which is looked up in the above table.
      #
      # @param name [Symbol] Column name.
      # @param type [Symbol] Column type.
      # @return [Entry] Column dictionary entry.
      def self.create(name:, type:)
        entry = ENTRY[type]
        new(name: name,
            eval: entry[:eval],              # Set if the column requires functions evaluated
            type: entry[:type],              # Column type
            set_if: entry[:set_if],          # Set if the column has a conditional default
            indexed: entry[:type] != :guard) # A guard column cannot be indexed.
      end

      # @return [Boolean] Return true is this is an input column, false otherwise.
      def ins?
        @ins
      end

      # @return [Symbol] Column name.
      attr_reader :name

      # @return [Symbol] Column type.
      attr_reader :type

      # @return [Boolean] Returns true if this column is indexed
      attr_accessor :indexed

      # @return [nil, Boolean] If set to true then this column has procs that
      #   need evaluating, otherwise it only contains constants.
      attr_accessor :eval

      # @return [nil, true, Symbol] Defined for columns of type :set, nil otherwise.
      #   If true, then default is set unconditionally, otherwise the method symbol
      #   sent to the input hash value that must evaluate to a truthy value.
      attr_reader :set_if

      # @return [Matchers::Proc, Object] For a column of type set: gives the proc that must be
      #   evaluated to set the default value. If not a proc, then it's some type of constant.
      attr_accessor :function

      # @param name (see #name)
      # @param type (see #type)
      # @param eval (see #eval)
      # @param set_if (see #set_if)
      # @param indexed (see #indexed)
      def initialize(name:, type:, eval: nil, set_if: nil, indexed: nil)
        @name = name
        @type = type
        @eval = eval
        @set_if = set_if
        @function = nil
        @ins = INS_TYPES.member?(type)
        @indexed = indexed
      end

      # Convert the object's attributes to a hash.
      #
      # @return [Hash{Symbol=>[nil, Boolean, Symbol]}]
      def to_h
        {
          name: @name,
          type: @type,
          eval: @eval,
          set_if: @set_if
        }
      end
    end

    # Classify and build a dictionary of all input and output columns by
    # parsing the header row.
    #
    # @param header [Array<String>] The header row after removing any empty columns.
    # @param dictionary [Columns::Dictionary] Table's columns dictionary.
    # @return [Columns::Dictionary] Table's columns dictionary.
    def self.build(header:, dictionary:)
      header.each_with_index do |cell, index|
        dictionary = parse_cell(cell: cell, index: index, dictionary: dictionary)
      end

      dictionary
    end

    def self.parse_cell(cell:, index:, dictionary:)
      column_type, column_name = Validate.column(cell: cell, index: index)

      dictionary_entry(dictionary: dictionary,
                       entry: Entry.create(name: column_name, type: column_type),
                       index: index)
    end
    private_class_method :parse_cell

    def self.dictionary_entry(dictionary:, entry:, index:)
      case entry.type
      # A guard column is still added to the ins hash for parsing as an input column.
      when :in, :guard, :set
        input_entry(dictionary: dictionary, entry: entry, index: index)

      when :out, :if
        output_entry(dictionary: dictionary, entry: entry, index: index)

      when :path
        dictionary.paths[index] = entry
      end

      dictionary
    end
    private_class_method :dictionary_entry

    def self.output_entry(dictionary:, entry:, index:)
      dictionary.outs[index] = entry

      case entry.type
      # if: columns are anonymous, even if the user names them
      when :if
        dictionary.ifs[index] = entry

      when :out
        Dictionary.add_name(columns: dictionary.columns, name: entry.name, out: index)
      end
    end
    private_class_method :output_entry

    def self.input_entry(dictionary:, entry:, index:)
      dictionary.ins[index] = entry

      # Default function will set the input value unconditionally or conditionally.
      dictionary.defaults[index] = entry if entry.type == :set

      # guard: columns are anonymous
      Dictionary.add_name(columns: dictionary.columns, name: entry.name) unless entry.type == :guard
    end
    private_class_method :input_entry
  end
end