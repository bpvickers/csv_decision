# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the CSV file's header row. These methods are only required at table load time.
  module Header
    # Column header looks like IN :col_name or if:
    COLUMN_TYPE = %r{
      \A(?<type>in|out|in/text|out/text|set|path)
      \s*:\s*(?<name>\S?.*)\z
    }xi

    # More lenient than a Ruby method name - any spaces will have been replaced with underscores
    COLUMN_NAME = %r{\A\w[\w:/!?]*\z}

    # These column types do not need a name
    COLUMN_TYPE_ANONYMOUS = Set.new(%i[path if guard]).freeze

    # Does this row contain a recognisable header cell?
    def self.row?(row)
      row.find { |cell| cell.match(Header::COLUMN_TYPE) }
    end

    # Parse the header row
    def self.parse(table:)
      CSVDecision::Columns.new(table)
    end

    def self.column?(cell:)
      match = Header::COLUMN_TYPE.match(cell)
      raise CellValidationError, 'column name is not well formed' unless match

      column_type = match['type']&.downcase&.to_sym
      column_name = column_name(type: column_type, name: match['name'])

      [column_type, column_name]
    rescue CellValidationError => exp
      raise CellValidationError,
            "header column '#{cell}' is not valid as #{exp.message}"
    end

    def self.column_name(type:, name:)
      return format_column_name(name) if name.present?
      return if COLUMN_TYPE_ANONYMOUS.member?(type)

      raise CellValidationError, 'the column name is missing'
    end

    def self.format_column_name(name)
      column_name = name.strip.tr("\s", '_')

      return column_name.to_sym if COLUMN_NAME.match(column_name)

      raise CellValidationError, "column name '#{name}' contains invalid characters"
    end

    # Returns the normalized column type, along with an indication if
    # the column is text only
    def self.column_type(type)
      case type
      when :'in/text'
        [:in, true]

      when :'out/text'
        [:out, true]

        # Column may turn out to be text-only, or not
      else
        [type, nil]
      end
    end

    def self.parse_row(dictionary:, row:)
      return unless row

      index = 0
      while index < row.count
        dictionary =
          Header.parse_cell(cell: row[index], index: index, dictionary: dictionary)

        index += 1
      end

      dictionary
    end

    def self.parse_cell(cell:, index:, dictionary:)
      return if cell == ''
      column_type, column_name = Header.column?(cell: cell)

      type, text_only = Header.column_type(column_type)

      dictionary_entry(dictionary: dictionary,
                       type: type,
                       name: column_name,
                       index: index,
                       text_only: text_only)
    end

    # Returns the normalized column type, along with an indication if
    # the column is text only.
    def self.dictionary_entry(dictionary:, type:, name:, index:, text_only:)
      entry = { name: name, text_only: text_only }

      case type
        # Header column that has a function for setting the value
        #       # Header column that has a function for setting the value
      when :set
        dictionary[:defaults][index] = { name: name, function: nil }
        # Treat set: as an in: column which may or may not be text-only.
        dictionary[:ins][index] = entry

      when :in
        dictionary[:ins][index] = entry

      when :out
        dictionary[:outs][index] = entry

      else
        raise "internal error - column type #{type} not recognised"
      end

      dictionary
    end
  end
end