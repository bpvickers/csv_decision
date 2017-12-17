# frozen_string_literal: true
require_relative '../../lib/csv_decsion/parse'

describe CSVDecision::Data do
  it 'parses a CSV string' do
    expect(CSVDecision::Data.to_array('')).to be_a(Array)
  end
end