# frozen_string_literal: true

require_relative '../../lib/csv_decision'

SPEC_DATA_VALID ||= File.join(CSVDecision.root, 'spec', 'data', 'valid')
SPEC_DATA_INVALID ||= File.join(CSVDecision.root, 'spec', 'data', 'invalid')

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
    table = CSVDecision.parse(data)

    expect(table.columns).to be_a(CSVDecision::Columns)
    expect(table.columns.ins[0].to_h).to eq(name: :input, text_only: nil)
    expect(table.columns.ins[2].to_h).to eq(name: :input, text_only: true)
    expect(table.columns.outs[1].to_h).to eq(name: :output, text_only: nil)
    expect(table.columns.outs[3].to_h).to eq(name: :output, text_only: true)
  end

  it 'parses a decision table columns from a CSV file' do
    file = Pathname(File.join(SPEC_DATA_VALID, 'valid.csv'))
    result = CSVDecision.parse(file)

    expect(result.columns).to be_a(CSVDecision::Columns)
    expect(result.columns.ins).to eq(0 => CSVDecision::Columns::Entry.with(name: :input, text_only: nil))
    expect(result.columns.outs).to eq(1 => CSVDecision::Columns::Entry.with(name: :output, text_only: nil))
  end

  it 'rejects an invalid header column' do
    data = [
      ['IN :input', 'BAD :output'],
      ['input', '']
    ]

    expect { CSVDecision.parse(data) }
      .to raise_error(CSVDecision::CellValidationError,
                      "header column 'BAD :output' is not valid as " \
                      'the column name is not well formed')
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
                      "the column name 'a-b' contains invalid characters")
  end

  context 'rejects invalid CSV decision table columns' do
    Dir[File.join(SPEC_DATA_INVALID, 'invalid_columns*.csv')].each do |file_name|
      pathname = Pathname(file_name)

      it "rejects CSV file #{pathname.basename}" do
        expect { CSVDecision.parse(pathname) }
          .to raise_error(CSVDecision::FileError, /\Aerror processing CSV file/)
      end
    end
  end
end