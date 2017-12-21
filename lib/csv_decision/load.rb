# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Load all the CSV files located in the designated folder path.
  def self.load(path, options = {})
    Load.path(path: path, options: options)
  end

  # Load all the CSV files located in the designated folder path.
  module Load
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