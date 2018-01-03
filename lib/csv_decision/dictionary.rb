# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the CSV file's header row. These methods are only required at table load time.
  # @api private
  module Dictionary
    COLUMN_ENTRY = {
      in:         { type: :in,    eval: nil },
      'in/text':  { type: :in,    eval: false },
      out:        { type: :out,   eval: nil },
      'out/text': { type: :out,   eval: false },
      guard:      { type: :guard, eval: true },
      if:         { type: :if,    eval: true }
    }.freeze
    private_constant :COLUMN_ENTRY

    # Value object to hold column dictionary entries.
    Entry = Struct.new(:name, :eval, :type) do
      def ins?
        %i[in guard].member?(type) ? true : false
      end
    end

    # Column name regular expression.
    COLUMN_NAME_RE = Matchers.regexp(Header::COLUMN_NAME)
    private_constant :COLUMN_NAME_RE

    # TODO: implement all anonymous column types
    # COLUMN_TYPE_ANONYMOUS = Set.new(%i[path if guard]).freeze
    # These column types do not need a name
    COLUMN_TYPE_ANONYMOUS = Set.new(%i[guard if]).freeze
    private_constant :COLUMN_TYPE_ANONYMOUS

    # Classify and build a dictionary of all input and output columns.
    #
    # @param row [Array<String>] The header row after removing any empty columns.
    # @return [Hash<Hash>] Column dictionary is a hash of hashes.
    def self.build(row:)
      dictionary = Columns::Dictionary.new

      row.each_with_index do |cell, index|
        dictionary = parse_cell(cell: cell, index: index, dictionary: dictionary)
      end

      validate(dictionary: dictionary)
    end

    def self.validate(dictionary:)
      dictionary.outs.each_pair do |col, column|
        validate_out(dictionary: dictionary, column_name: column.name, col: col)
      end

      dictionary
    end
    private_class_method :validate

    def self.validate_out(dictionary:, column_name:, col:)
      if input_column?(dictionary: dictionary, column_name: column_name)
        raise CellValidationError, "output column name '#{column_name}' is also an input column"
      end

      return unless dup_column?(dictionary: dictionary, column_name: column_name, col: col)
      raise CellValidationError, "output column name '#{column_name}' is duplicated"
    end
    private_class_method :validate_out

    def self.input_column?(dictionary:, column_name:)
      dictionary.ins.each_value { |column| return true if column_name == column.name }

      false
    end
    private_class_method :input_column?

    def self.dup_column?(dictionary:, column_name:, col:)
      dictionary.outs.each_pair do |key, column|
        return true if column_name == column.name && col != key
      end

      false
    end
    private_class_method :dup_column?

    def self.validate_column(cell:, index:)
      match = Header::COLUMN_TYPE.match(cell)
      raise CellValidationError, 'column name is not well formed' unless match

      column_type = match['type']&.downcase&.to_sym
      column_name = column_name(type: column_type, name: match['name'], index: index)

      [column_type, column_name]
    rescue CellValidationError => exp
      raise CellValidationError, "header column '#{cell}' is not valid as the #{exp.message}"
    end
    private_class_method :validate_column

    def self.column_name(type:, name:, index:)
      # If columns are named after their index, which is an integer and so cannot
      # clash with other column name types, which are symbols.
      return index if type == :if

      return format_column_name(name) if name.present?

      return if COLUMN_TYPE_ANONYMOUS.member?(type)

      raise CellValidationError, 'column name is missing'
    end
    private_class_method :column_name

    def self.format_column_name(name)
      column_name = name.strip.tr("\s", '_')

      return column_name.to_sym if COLUMN_NAME_RE.match(column_name)

      raise CellValidationError, "column name '#{name}' contains invalid characters"
    end
    private_class_method :format_column_name

    # Returns the normalized column type, along with an indication if
    # the column requires evaluation
    def self.column_type(column_name, type)
      entry = COLUMN_ENTRY[type]
      Entry.new(column_name, entry[:eval], entry[:type])
    end
    private_class_method :column_type

    def self.parse_cell(cell:, index:, dictionary:)
      column_type, column_name = validate_column(cell: cell, index: index)

      entry = column_type(column_name, column_type)

      dictionary_entry(dictionary: dictionary,
                       type: entry.type,
                       entry: entry,
                       index: index)
    end
    private_class_method :parse_cell

    def self.dictionary_entry(dictionary:, type:, entry:, index:)
      case type
      # Header column that has a function for setting the value (planned feature)
      # when :set, :'set/nil', :'set/blank'
      #   # Default function will set the input value unconditionally or conditionally
      #   dictionary.defaults[index] =
      #     Columns::Default.new(entry.name, nil, default_if(type))
      #
      #   # Treat set: as an in: column
      #   dictionary.ins[index] = entry

      when :in, :guard
        dictionary.ins[index] = entry

      when :out
        dictionary.outs[index] = entry

      when :if
        dictionary.outs[index] = entry
        dictionary.ifs[index] = entry
      end

      dictionary
    end
    private_class_method :dictionary_entry

    # def self.default_if(type)
    #   return nil if type == :set
    #   return :nil? if type == :'set/nil'
    #   :blank?
    # end
    # private_class_method :default_if
  end
end