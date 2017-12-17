# frozen_string_literal: true\

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.

require 'active_support/core_ext/object'
require 'csv_decision/table'

module CSVDecision
  autoload :Data,     'csv_decision/data'
  autoload :Parse,    'csv_decision/parse'
end