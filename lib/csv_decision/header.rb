# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the CSV file's header row. These methods are only required at table load time.
  # @api private
  module Header
    # TODO: implement all column types
    # COLUMN_TYPE = %r{
    #   \A(?<type>in|out|in/text|out/text|set|set/nil|set/blank|path|guard|if)
    #   \s*:\s*(?<name>\S?.*)\z
    # }xi

    # Column types recognised in the header row.
    COLUMN_TYPE = %r{
      \A(?<type>in|out|in/text|out/text|guard)
      \s*:\s*(?<name>\S?.*)\z
    }xi

    # TODO: implement all anonymous column types
    # COLUMN_TYPE_ANONYMOUS = Set.new(%i[path if guard]).freeze
    # These column types do not need a name
    COLUMN_TYPE_ANONYMOUS = Set.new(%i[guard]).freeze
    private_constant :COLUMN_TYPE_ANONYMOUS

    # Regular expression string for a column name.
    # More lenient than a Ruby method name - note any spaces will have been replaced with underscores.
    COLUMN_NAME = "\\w[\\w:/!?]*"

    # Column name regular expression.
    COLUMN_NAME_RE = Matchers.regexp(COLUMN_NAME)
    private_constant :COLUMN_NAME_RE

    # Check if the given row contains a recognisable header cell.
    #
    # @param row [Array<String>] Header row.
    # @return [Boolean] Return true if the row looks like a header.
    def self.row?(row)
      row.find { |cell| cell.match(COLUMN_TYPE) }
    end

    # Strip empty columns from all data rows.
    #
    # @param rows [Array<Array<String>>] Data rows.
    # @return [Array<Array<String>>] Data array after removing any empty columns and the
    #   header row.
    def self.strip_empty_columns(rows:)
      empty_cols = empty_columns?(row: rows.first)
      Data.strip_columns(data: rows, empty_columns: empty_cols) if empty_cols

      # Remove header row from the data array.
      rows.shift
    end

    # Classify and build a dictionary of all input and output columns.
    #
    # @param row [Array<String>] The header row after removing any empty columns.
    # @return [Hash<Hash>] Column dictionary is a hash of hashes.
    def self.dictionary(row:)
      dictionary = Columns::Dictionary.new

      row.each_with_index do |cell, index|
        dictionary = parse_cell(cell: cell, index: index, dictionary: dictionary)
      end

      dictionary
    end

    def self.validate_header_column(cell:)
      match = COLUMN_TYPE.match(cell)
      raise CellValidationError, 'column name is not well formed' unless match

      column_type = match['type']&.downcase&.to_sym
      column_name = column_name(type: column_type, name: match['name'])

      [column_type, column_name]
    rescue CellValidationError => exp
      raise CellValidationError,
            "header column '#{cell}' is not valid as the #{exp.message}"
    end
    private_class_method :validate_header_column

    # Array of all empty column indices.
    def self.empty_columns?(row:)
      result = []
      row&.each_with_index { |cell, index| result << index if cell == '' }

      result.empty? ? false : result
    end
    private_class_method :empty_columns?

    def self.column_name(type:, name:)
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
      case type
      when :'in/text'
        Columns::Entry.new(column_name, false, :in)

      when :guard
        Columns::Entry.new(column_name, true, :guard)

      when :'out/text'
        Columns::Entry.new(column_name, false, :out)

      # Column may turn out to be constants only, or not
      else
        Columns::Entry.new(column_name, nil, type.to_sym)
      end
    end
    private_class_method :column_type

    def self.parse_cell(cell:, index:, dictionary:)
      column_type, column_name = validate_header_column(cell: cell)

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