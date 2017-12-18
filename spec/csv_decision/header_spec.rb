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

  it 'rejects an invalid column header' do
    data = [
      ['IN :input', 'BAD :output'],
      ['input', '']
    ]

    expect { CSVDecision.parse(data) }
      .to raise_error(CSVDecision::CellValidationError,
                      "header column 'BAD :output' is not valid as " \
                      'column name is not well formed')
  end

  it 'rejects a missing column name' do
    data = [
      ['IN :input', 'IN: '],
      ['input', '']
    ]

    expect { CSVDecision.parse(data) }
      .to raise_error(CSVDecision::CellValidationError,
                      "header column 'IN:' is not valid as the column name is missing")
  end

  it 'rejects an invalid column name' do
    data = [
      ['IN :input', 'IN: a-b'],
      ['input', '']
    ]

    expect { CSVDecision.parse(data) }
      .to raise_error(CSVDecision::CellValidationError,
                      "header column 'IN: a-b' is not valid as " \
                      "column name 'a-b' contains invalid characters")
  end

  context 'rejects invalid CSV file decision table headers' do
    Dir[File.join(CSVDecision.root, 'spec/data/invalid/invalid_header*.csv')].each do |file_name|
      pathname = Pathname(file_name)

      it "rejects CSV file #{pathname.basename}" do
        expect { CSVDecision.parse(pathname) }
          .to raise_error(CSVDecision::FileError, /\Aerror processing CSV file/)
      end
    end
  end
end