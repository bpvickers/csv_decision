# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Parse and validate the column names in the header row.
  # These methods are only required at table load time.
  # @api private
  module Validate
    # These column types do not need a name.
    COLUMN_TYPE_ANONYMOUS = Set.new(%i[guard if path]).freeze
    private_constant :COLUMN_TYPE_ANONYMOUS

    # Validate a column header cell and return its type and name.
    #
    # @param cell [String] Header cell.
    # @param index [Integer] The header column's index.
    # @return [Array<(Symbol, Symbol)>] Column type and column name symbols.
    def self.column(cell:, index:)
      match = Header::COLUMN_TYPE.match(cell)
      raise CellValidationError, 'column name is not well formed' unless match

      column_type = match['type']&.downcase&.to_sym
      column_name = column_name(type: column_type, name: match['name'], index: index)

      [column_type, column_name]
    rescue CellValidationError => exp
      raise CellValidationError, "header column '#{cell}' is not valid as the #{exp.message}"
    end

    # Validate the column name against the dictionary of column names.
    #
    # @param columns [Symbol=>[false, Integer]] Column name dictionary.
    # @param name [Symbol] Column name.
    # @param out [false, Integer] False if an input column, otherwise the column index of
    #   the output column.
    # @return [void]
    # @raise [CellValidationError] Column name invalid.
    def self.name(columns:, name:, out:)
      return unless (in_out = columns[name])

      return validate_out_name(in_out: in_out, name: name) if out
      validate_in_name(in_out: in_out, name: name)
    end

    def self.column_name(type:, name:, index:)
      # if: columns are named after their index, which is an integer and so cannot
      # clash with other column name types, which are symbols.
      return index if type == :if

      return format_column_name(name) if name.present?

      return if COLUMN_TYPE_ANONYMOUS.member?(type)
      raise CellValidationError, 'column name is missing'
    end
    private_class_method :column_name

    def self.format_column_name(name)
      column_name = name.strip.tr("\s", '_')

      return column_name.to_sym if Header.column_name?(column_name)
      raise CellValidationError, "column name '#{name}' contains invalid characters"
    end
    private_class_method :format_column_name

    def self.validate_out_name(in_out:, name:)
      if in_out == :in
        raise CellValidationError, "output column name '#{name}' is also an input column"
      end

      raise CellValidationError, "output column name '#{name}' is duplicated"
    end
    private_class_method :validate_out_name

    def self.validate_in_name(in_out:, name:)
      # in: columns may be duped
      return if in_out == :in

      raise CellValidationError, "output column name '#{name}' is also an input column"
    end
    private_class_method :validate_in_name
  end
end