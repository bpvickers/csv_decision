# frozen_string_literal: true

describe CSVDecision::Columns do
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
    expect(table.columns.ins[0].to_h).to eq(name: :input, eval: nil, type: :in, set_if: nil)
    expect(table.columns.ins[2].to_h).to eq(name: :input, eval: false, type: :in, set_if: nil)
    expect(table.columns.outs[1].to_h).to eq(name: :output, eval: nil, type: :out, set_if: nil)
    expect(table.columns.outs[3].to_h).to eq(name: :output2, eval: false, type: :out, set_if: nil)

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
    expect(table.columns.ins[0].to_h).to eq(name: :input, eval: nil, type: :in, set_if: nil)
    expect(table.columns.ins[2].to_h).to eq(name: :input, eval: false, type: :in, set_if: nil)
    expect(table.columns.ins[5].to_h).to eq(name: nil, eval: true, type: :guard, set_if: nil)

    expect(table.columns.outs[1].to_h).to eq(name: :output, eval: nil, type: :out, set_if: nil)
    expect(table.columns.outs[3].to_h).to eq(name: :output2, eval: false, type: :out, set_if: nil)
    expect(table.columns.outs[4].to_h).to eq(name: :len, eval: true, type: :out, set_if: nil)

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
    expect(table.columns.ins[0].to_h).to eq(name: :input, eval: nil, type: :in, set_if: nil)
    expect(table.columns.ins[2].to_h).to eq(name: :input, eval: false, type: :in, set_if: nil)
    expect(table.columns.outs[1].to_h).to eq(name: :output, eval: nil, type: :out, set_if: nil)
    expect(table.columns.outs[3].to_h).to eq(name: :output2, eval: false, type: :out, set_if: nil)
    expect(table.columns.outs[4].to_h).to eq(name: :input3, eval: true, type: :out, set_if: nil)
    expect(table.columns.outs[5].to_h).to eq(name: :len, eval: true, type: :out, set_if: nil)

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
    expect(result.columns.ins.count).to eq 1
    expect(result.columns.outs.count).to eq 1
    expect(result.columns.ins[0].to_h).to eql(name: :input, type: :in, eval: nil, set_if: nil)
    expect(result.columns.outs[1].to_h).to eql(name: :output, type: :out, eval: nil, set_if: nil)
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
      .to eq(name: nil, eval: true, type: :guard, set_if: nil)

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

    expect(table.columns.ifs[3].to_h).to eq(name: 3, eval: true, type: :if, set_if: nil)
    expect(table.columns.input_keys).to eq %i[country CUSIP SEDOL]
  end

  it 'recognises the set: columns' do
    data = <<~DATA
      set/nil? :country, guard:,          set: class,    out :PAID, out: len,     if:
      US,                ,                :class.upcase,
      US,                :CUSIP.present?, != PRIVATE,    :CUSIP,    :PAID.length, :len == 9
      !=US,              :ISIN.present?,  != PRIVATE,    :ISIN,     :PAID.length, :len == 12
    DATA
    table = CSVDecision.parse(data)

    expect(table.columns.ins[0].to_h).to eq(name: :country, eval: nil, type: :set, set_if: :nil?)
    expect(table.columns.ins[1].to_h).to eq(name: nil, eval: true, type: :guard, set_if: nil)
    expect(table.columns.ins[2].to_h).to eq(name: :class, eval: nil, type: :set, set_if: true)

    expect(table.columns.input_keys).to eq %i[country class CUSIP ISIN]
  end

  it 'recognises the path: columns' do
    data = <<~DATA
      path:,   path:,    in :type_cd, out :value, if:
      header,  ,         !nil?,       :type_cd,   :value.present?
      payload, ,         !nil?,       :type_cd,   :value.present?
      payload, ref_data, ,            :type_id,   :value.present?
    DATA
    table = CSVDecision.parse(data)

    expect(table.columns.input_keys).to eq %i[type_cd type_id]
    expect(table.columns.paths[0].to_h).to eq(name: nil, eval: false, type: :path, set_if: nil)
    expect(table.columns.paths[1].to_h).to eq(name: nil, eval: false, type: :path, set_if: nil)
  end
end