# frozen_string_literal: true

require_relative '../../lib/csv_decision'

describe CSVDecision::Decision do
  it 'decision for table with no functions and first_match: true' do
    data = <<~DATA
      IN :input, OUT :output, IN: input1
      input0,    output0,     input1
      input0,    output1,
    DATA

    table = CSVDecision.parse(data)

    input = { input: 'input0', input1: 'input1' }

    decision = CSVDecision::Decision.new(table: table, input: input)

    expect(decision).to be_a(CSVDecision::Decision)
  end
end