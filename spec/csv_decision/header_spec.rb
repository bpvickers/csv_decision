# frozen_string_literal: true

require_relative '../../lib/csv_decision'

describe CSVDecision::Header do
  describe '#new' do
    it 'creates a Header object' do
      table = CSVDecision::Table.new
      header = CSVDecision::Header.new(table)

      expect(header).to be_a(CSVDecision::Header)
      expect(header.table).to eq table
    end
  end

  it 'parses a decision table header from a CSV file' do
    file = Pathname(File.join(CSVDecision.root, 'spec/data/valid', 'valid.csv'))
    result = CSVDecision.parse(file)

    expected = [
      ['IN :input', 'OUT :output'],
      ['input', '']
    ]

    expect(result.header).to be_a(CSVDecision::Header)
    # expect(result.header.ins).to eq expected
  end


end