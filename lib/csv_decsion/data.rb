# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Methods to load data from a file, CSV string or array of arrays
  module Data
    # Parse the input data which may either be a file path name, CSV string or
    # array of arrays
    def self.to_array(_input)
      []
    end
  end
end