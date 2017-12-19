# frozen_string_literal: true

require_relative '../../lib/csv_decision'

describe CSVDecision::Columns do
  describe '#new' do
    it 'creates a columns object' do
      table = CSVDecision::Table.new
      columns = CSVDecision::Columns.new(table)

      expect(columns).to be_a(CSVDecision::Columns)
    end
  end

  it 'parses a decision table columns from a CSV file' do
    data = <<~DATA
      IN :input, OUT :output, IN/text : input, OUT/text:output
      input0,    output0,     input1,          output1
    DATA
    result = CSVDecision.parse(data)

    expect(result.columns).to be_a(CSVDecision::Columns)
    expect(result.columns.ins[0]).to eq(name: :input, text_only: nil)
    expect(result.columns.ins[2]).to eq(name: :input, text_only: true)
    expect(result.columns.outs[1]).to eq(name: :output, text_only: nil)
    expect(result.columns.outs[3]).to eq(name: :output, text_only: true)
  end

  it 'parses a decision table columns from a CSV file' do
    file = Pathname(File.join(CSVDecision.root, 'spec/data/valid', 'valid.csv'))
    result = CSVDecision.parse(file)

    expect(result.columns).to be_a(CSVDecision::Columns)
    expect(result.columns.ins).to eq(0 => { name: :input, text_only: nil })
    expect(result.columns.outs).to eq(1 => { name: :output, text_only: nil })
  end

  it 'rejects an invalid column columns' do
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

  context 'rejects invalid CSV file decision table columnss' do
    Dir[File.join(CSVDecision.root, 'spec/data/invalid/invalid_columns*.csv')].each do |file_name|
      pathname = Pathname(file_name)

      it "rejects CSV file #{pathname.basename}" do
        expect { CSVDecision.parse(pathname) }
          .to raise_error(CSVDecision::FileError, /\Aerror processing CSV file/)
      end
    end
  end
end