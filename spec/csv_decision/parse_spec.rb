# frozen_string_literal: true
require_relative '../../lib/csv_decision/parse'

describe CSVDecision::Parse do
  it 'loads a decision table' do
    table =  CSVDecision.parse('')
    expect(table).to be_a CSVDecision::Table
    expect(table.frozen?).to eq true
    expect(table.rows.empty?).to eq true
  end
end