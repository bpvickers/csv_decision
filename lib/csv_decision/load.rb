# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017.
# @author Brett Vickers <brett@phillips-vickers.com>
# See LICENSE and README.md for details.
module CSVDecision
  # Load all the CSV files located in the designated folder path.
  #
  # @param path [Pathname] Directory containing CSV files.
  # @param options [Hash] Supplied options hash for table creation.
  # @return [Hash<CSVDecision::Table>]
  # @raise [ArgumentError] Invalid folder.
  def self.load(path, options = {})
    Load.path(path: path, options: options)
  end

  # Load all CSV files located in the specified folder.
  # @api private
  module Load
    # (see CSVDecision.load)
    def self.path(path:, options:)
      raise ArgumentError, 'path argument must be a Pathname' unless path.is_a?(Pathname)
      raise ArgumentError, 'path argument not a valid folder' unless path.directory?

      tables = {}
      Dir[path.join('*.csv')].each do |file_name|
        table_name = File.basename(file_name, '.csv').to_sym
        tables[table_name] = CSVDecision.parse(Pathname(file_name), options)
      end

      tables.freeze
    end
  end
end