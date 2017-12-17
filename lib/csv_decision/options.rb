# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the CSV file and create a new decision table object
  class Options
    attr_accessor :options

    def initialize(options)
      options.deep_dup
    end
  end
end