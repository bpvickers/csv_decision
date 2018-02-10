# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Scan the input hash for all the paths specified in the decision table
  # @api private
  class Scan
    # Main method for making decisions with a table that has paths.
    #
    # @param table [CSVDecision::Table] Decision table.
    # @param input [Hash] Input hash (keys may or may not be symbolized)
    # @param symbolize_keys [Boolean] Set to false if keys are symbolized and it's
    #   OK to mutate the input hash. Otherwise a copy of the input hash is symbolized.
    # @return [Hash{Symbol=>Object}] Decision result.
    def self.table(table:, input:, symbolize_keys:)
      scan_table(table: table,
                 input: symbolize_keys ? input.deep_symbolize_keys : input,
                 decision: Decision.new(table: table))
    end

    def self.scan_table(table:, input:, decision:)
      # Final result
      final = {}
      input_hashes = InputHashes.new(table)

      table.path.each do |path, rows|
        data = input_hashes.data(path: path, input: input)
        decision.reinitialize(input: data)

        final = scan(rows: Array(rows), input: data, final: final)
      end

      final
    end

    def self.scan(rows:, input:, final:)
      rows = Array(rows)
      hash = input[:hash]
      scan_cols = input[:scan_cols]
      if table.first_match
        result = decision.index_scan_first_match(scan_cols: scan_cols, hash: hash, index_rows: rows)
        return result unless result.empty?
      else
        result = decision.index_scan_accumulate(scan_cols: scan_cols, hash: hash, index_rows: rows)
        final = accumulate(final: final, result: result)
      end

      final
    end

    def self.accumulate(final:, result:)
      return result if final.empty?

      final.each_pair { |key, value| final[key] = Array(value) + Array(result[key]) }
      final
    end

    # Cache the parsed input hash
    class InputHashes
      def initialize(table)
        @table = table
        @input_hashes = {}
      end

      def data(path:, input:)
        return @input_hashes[path] if @input_hashes.key?(path)

        # Parse and transform the hash supplied as input
        hash = path.empty? ? input : input.dig(*path)
        data = Input.parse_data(table: @table, input: hash)
        @input_hashes[path] = data
      end
    end
  end
end