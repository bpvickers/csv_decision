# frozen_string_literal: true

require_relative '../../lib/csv_decision'

describe CSVDecision::Load do
  path = Pathname(File.join(CSVDecision.root, 'spec/data/valid'))

  it "loads all valid CSV files in the directory" do
    tables = CSVDecision.load(path, first_match: false, regexp_implicit: true)
    expect(tables).to be_a Hash
    expect(tables.count).to eq Dir[path.join('*.csv')].count

    tables.each_pair do |name, table|
      expect(name).to be_a(Symbol)
      expect(table).to be_a(CSVDecision::Table)
    end
  end

  it 'rejects an invalid path name' do
    expect { CSVDecision.load('path') }
      .to raise_error(ArgumentError, 'path argument must be a Pathname')
  end

  it 'rejects an invalid folder name' do
    expect { CSVDecision.load(Pathname('path')) }
      .to raise_error(ArgumentError, 'path argument not a valid folder')
  end
end