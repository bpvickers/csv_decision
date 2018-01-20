# frozen_string_literal: true

require_relative '../../lib/csv_decision'

describe CSVDecision::Input do
  it 'rejects a non-hash or empty hash value' do
    expect { CSVDecision::Input.parse(table: nil, input: [], symbolize_keys: true ) }
      .to raise_error(ArgumentError, 'input must be a non-empty hash')
    expect { CSVDecision::Input.parse(table: nil, input: {}, symbolize_keys: true ) }
      .to raise_error(ArgumentError, 'input must be a non-empty hash')
  end

  it 'processes input hash with symbolize_keys: true' do
    data = <<~DATA
      IN :input, OUT :output, IN: input1
      input0,    output0,     input1
      input0,    output1,
    DATA

    table = CSVDecision.parse(data)

    input = { 'input' => 'input0', input1: 'input1' }
    expected = {
      hash: { input: 'input0', input1: 'input1' },
      scan_cols: { 0 => 'input0', 2 => 'input1'},
      key: 'input0'
    }

    result = CSVDecision::Input.parse(table: table, input: input, symbolize_keys: true)

    expect(result).to eql expected
    expect(result[:hash]).not_to equal expected[:hash]
    expect(result[:hash].frozen?).to eq true
  end

  it 'processes input hash with symbolize_keys: false' do
    data = <<~DATA
      IN :input, OUT :output, IN: input1
      input0,    output0,     input1
      input0,    output1,
    DATA

    table = CSVDecision.parse(data)
    input = { input: 'input0', input1: 'input1' }
    expected = {
      hash: input,
      scan_cols: { 0 => 'input0', 2 => 'input1'},
      key: 'input0'
    }

    result = CSVDecision::Input.parse(table: table, input: input, symbolize_keys: false)

    expect(result).to eql expected
    expect(result[:hash]).to equal expected[:hash]
    expect(result[:hash].frozen?).to eq false
  end
end