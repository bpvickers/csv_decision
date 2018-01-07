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

  it 'rejects a duplicate output column name' do
    data = <<~DATA
      IN :input, OUT :output, IN/text : input, OUT/text:output
      input0,    output0,     input1,          output1
    DATA
    expect { CSVDecision.parse(data) }
      .to raise_error(CSVDecision::CellValidationError,
                      "output column name 'output' is duplicated")
  end

  it 'parses a decision table columns from a CSV string' do
    data = <<~DATA
      IN :input, OUT :output, IN/text : input, OUT/text:output2
      input0,    output0,     input1,          output1
    DATA
    table = CSVDecision.parse(data)

    expect(table.columns).to be_a(CSVDecision::Columns)
    expect(table.columns.ins[0].to_h).to eq(name: :input, eval: nil, type: :in)
    expect(table.columns.ins[2].to_h).to eq(name: :input, eval: false, type: :in)
    expect(table.columns.outs[1].to_h).to eq(name: :output, eval: nil, type: :out)
    expect(table.columns.outs[3].to_h).to eq(name: :output2, eval: false, type: :out)

    expect(table.columns.dictionary).to eq(input: :in, output: 1, output2: 3)
  end

  it 'recognises all input and output column symbols' do
    data = <<~DATA
      IN :input, OUT :output, IN/text :input, OUT/text:output2, out: len,       guard:
      input0,    output0,     input1,         output1,          :input2.length, 
      input1,    output1,     input1,         output2,          :input3.length, :input4.present?
    DATA
    table = CSVDecision.parse(data)

    expect(table.columns).to be_a(CSVDecision::Columns)
    expect(table.columns.ins[0].to_h).to eq(name: :input, eval: nil, type: :in)
    expect(table.columns.ins[2].to_h).to eq(name: :input, eval: false, type: :in)
    expect(table.columns.ins[5].to_h).to eq(name: nil, eval: true, type: :guard)

    expect(table.columns.outs[1].to_h).to eq(name: :output, eval: nil, type: :out)
    expect(table.columns.outs[3].to_h).to eq(name: :output2, eval: false, type: :out)
    expect(table.columns.outs[4].to_h).to eq(name: :len, eval: true, type: :out)

    expect(table.columns.dictionary)
      .to eq(input: :in, output: 1, output2: 3, len: 4, input2: :in, input3: :in, input4: :in)

    expect(table.columns.input_keys).to eq %i[input input2 input4 input3]
  end

  it 'recognises the output symbol referenced by an output function' do
    data = <<~DATA
      IN :input, OUT :output, IN/text :input, OUT/text:output2, out: input3,      out: len       
      input0,    output0,     input1,         output1,          ,                 :input2.length
      input1,    output1,     input1,         output2,          :input4.present?, :input3.length
    DATA

    table = CSVDecision.parse(data)

    expect(table.columns).to be_a(CSVDecision::Columns)
    expect(table.columns.ins[0].to_h).to eq(name: :input, eval: nil, type: :in)
    expect(table.columns.ins[2].to_h).to eq(name: :input, eval: false, type: :in)
    expect(table.columns.outs[1].to_h).to eq(name: :output, eval: nil, type: :out)
    expect(table.columns.outs[3].to_h).to eq(name: :output2, eval: false, type: :out)
    expect(table.columns.outs[4].to_h).to eq(name: :input3, eval: true, type: :out)
    expect(table.columns.outs[5].to_h).to eq(name: :len, eval: true, type: :out)

    expect(table.columns.dictionary)
      .to eq(input: :in, output: 1, output2: 3, len: 5, input2: :in, input3: 4, input4: :in)

    expect(table.columns.input_keys).to eq %i[input input2 input4]
  end

  it 'raises an error for an output column referring to a later output column' do
    data = <<~DATA
      IN :input, OUT :output, IN/text :input, OUT/text:output2, out: len,        out: input3,            
      input0,    output0,     input1,         output1,          :input2.length,                 
      input1,    output1,     input1,         output2,          :input3.length   :input4.upcase
    DATA

    expect { CSVDecision.parse(data) }
      .to raise_error(
        CSVDecision::CellValidationError,
        "output column 'len' makes an out of order reference to output column 'input3'"
      )
  end

  it 'raises an error for an output column referring to itself' do
    data = <<~DATA
      IN :input, OUT :output, IN/text :input, OUT/text:output2, out: len,      out: input3,            
      input0,    output0,     input1,         output1,          :len.length,                 
      input1,    output1,     input1,         output2,          :len.length   :input4.upcase
    DATA

    expect { CSVDecision.parse(data) }
      .to raise_error(CSVDecision::CellValidationError,
                      "output column 'len' makes reference to itself")
  end

  it 'parses a decision table columns from a CSV file' do
    file = Pathname(File.join(SPEC_DATA_VALID, 'valid.csv'))
    result = CSVDecision.parse(file)

    expect(result.columns).to be_a(CSVDecision::Columns)
    expect(result.columns.ins)
      .to eq(0 => CSVDecision::Dictionary::Entry.new(:input, nil, :in))
    expect(result.columns.outs)
      .to eq(1 => CSVDecision::Dictionary::Entry.new(:output, nil, :out))
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
    Dir[File.join(SPEC_DATA_INVALID, 'invalid_header*.csv')].each do |file_name|
      pathname = Pathname(file_name)

      it "rejects CSV file #{pathname.basename}" do
        expect { CSVDecision.parse(pathname) }
          .to raise_error(CSVDecision::FileError, /\Aerror processing CSV file/)
      end
    end
  end

  it 'recognises the guard column' do
    data = <<~DATA
      IN :country, guard:,          out :PAID, out :PAID_type
      US,          :CUSIP.present?, :CUSIP,    CUSUP
      GB,          :SEDOL.present?, :SEDOL,    SEDOL
    DATA
    table = CSVDecision.parse(data)

    expect(table.columns.ins[1].to_h)
      .to eq(name: nil, eval: true, type: :guard)

    expect(table.columns.input_keys).to eq %i[country CUSIP SEDOL]
  end

  it 'rejects output column being same as input column' do
    data = <<~DATA
      IN :country, guard:,          out :PAID, out :country
      US,          :CUSIP.present?, :CUSIP,    CUSUP
      GB,          :SEDOL.present?, :SEDOL,    SEDOL
    DATA

    expect { CSVDecision.parse(data) }
      .to raise_error(CSVDecision::CellValidationError,
                      "output column name 'country' is also an input column")
  end

  it 'rejects output column being same as an input symbol not in the header' do
    data = <<~DATA
      in :parent, out :node
      ==:node,    top
      ,           child
    DATA
    expect { CSVDecision.parse(data) }
      .to raise_error(CSVDecision::CellValidationError,
                      "output column name 'node' is also an input column")
  end

  it 'recognises the if: column' do
    data = <<~DATA
      in :country, out :PAID, out :PAID_type, if:
      US,          :CUSIP,    CUSIP,          :PAID.present?
      GB,          :SEDOL,    SEDOL,          :PAID.present?
    DATA
    table = CSVDecision.parse(data)

    expect(table.columns.ifs[3].to_h).to eq(name: 3, eval: true, type: :if)
    expect(table.columns.input_keys).to eq %i[country CUSIP SEDOL]
  end
end