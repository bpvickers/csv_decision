# frozen_string_literal: true
require_relative '../../lib/csv_decision/parse'

describe CSVDecision::Parse do
  it 'loads an empty decision table' do
    table =  CSVDecision.parse('')
    expect(table).to be_a CSVDecision::Table
    expect(table.frozen?).to eq true
    expect(table.rows.empty?).to eq true
  end

  it 'parses a decision table from a CSV file' do
    file = Pathname(File.join(CSVDecision.root, 'spec/data/valid', 'valid.csv'))
    result = CSVDecision.parse(file)

    expected = [
      ['IN :input', 'OUT :output'],
      ['input', '']
    ]

    expect(result).to be_a(CSVDecision::Table)
    expect(result.rows).to eq expected
  end

  context 'it parses valid CSV files' do
    Dir[File.join(CSVDecision.root, 'spec/data/valid/*.csv')].each do |file_name|
      pathname = Pathname(file_name)

      it "loads CSV file #{pathname.basename}" do
        expect { CSVDecision.parse(pathname) }.not_to raise_error
        expect(CSVDecision.parse(pathname)).to be_a CSVDecision::Table
      end
    end
  end
end