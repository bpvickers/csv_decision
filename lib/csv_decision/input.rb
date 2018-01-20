# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the input hash.
  # @api private
  module Input
    # @param (see Decide.decide)
    # @return [Hash{Symbol => Hash{Symbol=>Object}, Hash{Integer=>Object}}]
    #   Returns  a hash of two hashes:
    #   * hash: either a copy with keys symbolized or the original input object
    #   * scan_cols: Picks out the value in the input hash for each table input column.
    #     Defaults to nil if the key is missing in the input hash.
    def self.parse(table:, input:, symbolize_keys:)
      validate(input)

      hash, scan_cols =
        parse_input(table: table, input: symbolize_keys ? input.symbolize_keys : input)

      index_key = table.index ? parse_key(table: table, hash: hash) : nil

      # We can freeze the input hash for safety if we made our own copy.
      [symbolize_keys ? hash.freeze : hash, scan_cols.freeze, index_key]
    end

    def self.parse_key(table:, hash:)
      return scan_key(table: table, hash: hash) if table.index.columns.count == 1

      scan_keys(table: table, hash: hash).freeze
    end
    private_class_method :parse_key

    def self.scan_key(table:, hash:)
      col = table.index.columns[0]
      column = table.columns.ins[col]

      hash[column.name]
    end
    private_class_method :scan_key

    def self.scan_keys(table:, hash:)
      table.index.columns.map do |col|
        column = table.columns.ins[col]

        hash[column.name]
      end
    end
    private_class_method :scan_keys

    def self.validate(input)
      return if input.is_a?(Hash) && !input.empty?
      raise ArgumentError, 'input must be a non-empty hash'
    end
    private_class_method :validate

    def self.parse_input(table:, input:)
      defaulted_columns = table.columns.defaults

      # Code path optimized for no defaults
      return parse_cells(table: table, input: input) if defaulted_columns.empty?

      parse_defaulted(table: table, input: input, defaulted_columns: defaulted_columns)
    end

    private_class_method :parse_input

    def self.parse_cells(table:, input:)
      scan_cols = {}
      table.columns.ins.each_pair do |col, column|
        next if column.type == :guard

        scan_cols[col] = input[column.name]
      end

      [input, scan_cols]
    end

    private_class_method :parse_cells

    def self.parse_defaulted(table:, input:, defaulted_columns:)
      scan_cols = {}

      table.columns.ins.each_pair do |col, column|
        next if column.type == :guard

        scan_cols[col] =
          default_value(default: defaulted_columns[col], input: input, column: column)

        # Also update the input hash with the default value.
        input[column.name] = scan_cols[col]
      end

      [input, scan_cols]
    end

    private_class_method :parse_defaulted

    def self.default_value(default:, input:, column:)
      value = input[column.name]

      # Do we even have a default entry for this column?
      return value if default.nil?

      # Has the set condition been met, or is it unconditional?
      return value unless default_if?(default.set_if, value)

      # Expression may be a Proc that needs evaluating against the input hash,
      # or else a constant.
      eval_default(default.function, input)
    end

    private_class_method :default_value

    def self.default_if?(set_if, value)
      set_if == true || (value.respond_to?(set_if) && value.send(set_if))
    end

    private_class_method :default_if?

    # Expression may be a Proc that needs evaluating against the input hash,
    # or else a constant.
    def self.eval_default(expression, input)
      expression.is_a?(::Proc) ? expression[input] : expression
    end

    private_class_method :eval_default
  end
end