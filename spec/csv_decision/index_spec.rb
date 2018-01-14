# frozen_string_literal: true

require_relative '../../lib/csv_decision'

SPEC_DATA_VALID ||= File.join(CSVDecision.root, 'spec', 'data', 'valid')
SPEC_DATA_INVALID ||= File.join(CSVDecision.root, 'spec', 'data', 'invalid')

describe CSVDecision::Index do
  it 'indexes a single column CSV' do
    file = Pathname(File.join(SPEC_DATA_VALID, 'options_in_file3.csv'))
    result = CSVDecision.parse(file)

    expected = {
      'none' => 0,
      'one' => 1,
      'two' => 2,
      'three' => 3,
      nil => 4,
      0 => 5,
      1 => 6,
      2 => 7,
      3 => 8
    }

    expect(result.index.keys).to eq [0]
    expect(result.index.hash).to eql expected
  end

  it 'rejects index value greater than number of input columns' do
    file = Pathname(File.join(SPEC_DATA_INVALID, 'index_too_big.csv'))

    expect { CSVDecision.parse(file) }
      .to raise_error(CSVDecision::FileError,
                      /option :index value of 2 exceeds number of input columns/)
  end

  it 'rejects index on guard column' do
    file = Pathname(File.join(SPEC_DATA_INVALID, 'index_guard_column.csv'))

    expect { CSVDecision.parse(file) }
      .to raise_error(CSVDecision::FileError,
                      /option :index value of 2 exceeds number of input columns/)
  end
end