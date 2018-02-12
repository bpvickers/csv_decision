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
      input = symbolize_keys ? input.deep_symbolize_keys : input
      decision = Decision.new(table: table)
      input_hashes = InputHashes.new

      if table.options[:first_match]
        scan_first_match(input: input, decision: decision, input_hashes: input_hashes)
      else
        scan_accumulate(input: input, decision: decision, input_hashes: input_hashes)
      end
    end

    def self.scan_first_match(input:, decision:, input_hashes:)
      decision.table.paths.each do |path, rows|
        data = input_hashes.data(decision: decision, path: path, input: input)
        next if data == {}

        # Note that +rows+ must be enclosed in an array for this method to work.
        result = decision.index_scan_first_match(
          scan_cols: data[:scan_cols],
          hash: data[:hash],
          index_rows: [rows]
        )
        return result if result != {}
      end

      {}
    end
    private_class_method :scan_first_match

    def self.scan_accumulate(input:, decision:, input_hashes:)
      # Final result
      result = {}

      decision.table.paths.each do |path, rows|
        data = input_hashes.data(decision: decision, path: path, input: input)
        next if data == {}

        result = scan(rows: rows, input: data, final: result, decision: decision)
      end

      result
    end
    private_class_method :scan_accumulate

    def self.scan(rows:, input:, final:, decision:)
      # Note that +rows+ must be enclosed in an array for this method to work.
      result = decision.index_scan_accumulate(scan_cols: input[:scan_cols],
                                              hash: input[:hash],
                                              index_rows: [rows])

      # Accumulate this potentially multi-row result into the final result.
      final = accumulate(final: final, result: result) if result.present?

      final
    end
    private_class_method :scan

    def self.accumulate(final:, result:)
      return result if final == {}

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
      def data(decision:, path:, input:)
        result = input(decision: decision, path: path, input: input)

        decision.input(result) unless result == {}

        result
      end

      private

      def input(decision:, path:, input:)
        return @input_hashes[path] if @input_hashes.key?(path)

        # Use the path - an array of symbol keys, to dig out the input sub-hash
        hash = path.empty? ? input : input.dig(*path)

        # Parse and transform the hash supplied as input
        data = hash.blank? ? {} : Input.parse_data(table: decision.table, input: hash)

        # Cache the parsed input hash data for this path
        @input_hashes[path] = data
      end
    end
  end
end