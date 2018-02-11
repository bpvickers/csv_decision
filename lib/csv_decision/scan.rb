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
      scan_table(
        table: table,
        input: symbolize_keys ? input.deep_symbolize_keys : input,
        decision: Decision.new(table: table),
        input_hashes: InputHashes.new
      )
    end

    def self.scan_table(table:, input:, decision:, input_hashes:)
      # Final result
      result = {}

      table.paths.each do |path, rows|
        data = input_hashes.data(table: table, path: path, input: input)
        next if data == {}

        decision.input(data)

        result = scan(rows: rows, input: data, final: result, decision: decision)
        return result if table.options[:first_match] && !result.empty?
      end

      result
    end
    private_class_method :scan_table

    def self.scan(rows:, input:, final:, decision:)
      rows = Array(rows)
      hash = input[:hash]
      scan_cols = input[:scan_cols]
      if decision.first_match
        result = decision.index_scan_first_match(scan_cols: scan_cols, hash: hash, index_rows: rows)
        return result unless result.empty?
      else
        result = decision.index_scan_accumulate(scan_cols: scan_cols, hash: hash, index_rows: rows)
        final = accumulate(final: final, result: result) if result
      end

      final
    end
    private_class_method :scan

    def self.accumulate(final:, result:)
      return result if final.empty?

      final.each_pair { |key, value| final[key] = Array(value) + Array(result[key]) }
      final
    end
    private_class_method :accumulate

    # Derive the parsed input hash, using a cache for speed.
    class InputHashes
      def initialize
        @input_hashes = {}
      end

      # @param path [Array<Symbol] Path for the input hash.
      # @param input [Hash{Symbol=>Object}] Input hash.
      # @return [Hash{Symbol=>Object}] Parsed input hash.
      def data(table:, path:, input:)
        return @input_hashes[path] if @input_hashes.key?(path)

        # Use the path - an array of symbol keys, to dig out the input sub-hash
        hash = path.empty? ? input : input.dig(*path)

        # Parse and transform the hash supplied as input
        data = hash.blank? ? {} : Input.parse_data(table: table, input: hash)

        # Cache the parsed input hash data for this path
        @input_hashes[path] = data
      end
    end
  end
end