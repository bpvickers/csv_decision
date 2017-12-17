# frozen_string_literal: true\

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.

require 'active_support/core_ext/object'
require_relative '../lib/csv_decision/table'

module CSVDecision
  # @return [String] gem project's root directory
  def self.root
    File.dirname __dir__
  end

  autoload :Data,     'csv_decision/data'
  autoload :Options,  'csv_decision/options'
  autoload :Parse,    'csv_decision/parse'
end