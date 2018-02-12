# frozen_string_literal: true

describe CSVDecision::Decision do
  it 'decision for table with no functions and first_match: true' do
    data = <<~DATA
      IN :input, OUT :output, IN: input1
      input0,    output0,     input1
      input0,    output1,
    DATA

    table = CSVDecision.parse(data)

    decision = CSVDecision::Decision.new(table: table)

    expect(decision).to be_a(CSVDecision::Decision)
  end
end