# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the CSV file's header row and initialize a CSVDecision::Header object.
  module ParseHeader
    # More lenient than a Ruby method name - any spaces will have beeb replaced with underscores
    COLUMN_NAME = %r{\A\w[\w:/!?]*\z}

    COLUMN_TYPE_ANONYMOUS = Set.new(%i[path if guard]).freeze

    # Does this row contain a recognisable header cell?
    def self.row?(row)
      row.find { |cell| cell.match(Header::COLUMN_TYPE) }
    end

    # Parse the header row
    def self.parse(table:, options: {})
      header = CSVDecision::Header.new(table)

      header.freeze
    end

    def self.column?(cell:)
      match = Header::COLUMN_TYPE.match(cell)
      raise CellValidationError, 'column name is not well formed' unless match

      column_type = column_type(type: match['type'])
      column_name = column_name(type: column_type, name: match['name'])

      [column_type, column_name]

    rescue CellValidationError => exp
      raise CellValidationError,
            "header column '#{cell}' is not valid as #{exp.message}"
    end

    def self.column_type(type:)
      return type.downcase.to_sym
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
  end
end