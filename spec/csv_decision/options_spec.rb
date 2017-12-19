# frozen_string_literal: true

require_relative '../../lib/csv_decision'

SPEC_DATA_VALID ||= File.join(CSVDecision.root, 'spec', 'data', 'valid')

describe CSVDecision::Options do
  it 'sets the default options' do
    data = <<~DATA
      IN :input, OUT :output
      input0,    output0
    DATA

    result = CSVDecision.parse(data)

    expected = {
      first_match: true,
      regexp_implicit: false,
      text_only: false,
      index: nil,
      tables: nil,
      matchers: CSVDecision::DEFAULT_MATCHERS
    }
    expect(result.options).to eql expected
  end

  it 'overrides the default options' do
    data = <<~DATA
      IN :input, OUT :output
      input0,    output0
    DATA

    result = CSVDecision.parse(data, first_match: false)

    expected = {
      first_match: false,
      regexp_implicit: false,
      text_only: false,
      index: nil,
      tables: nil,
      matchers: CSVDecision::DEFAULT_MATCHERS
    }
    expect(result.options).to eql expected
  end

  it 'parses options from a CSV file' do
    file = Pathname(File.join(SPEC_DATA_VALID, 'options_in_file1.csv'))
    result = CSVDecision.parse(file)

    expected = {
      first_match: false,
      regexp_implicit: false,
      text_only: false,
      index: nil,
      tables: nil,
      matchers: CSVDecision::DEFAULT_MATCHERS
    }
    expect(result.options).to eql expected
  end

  it 'options from the CSV file override method options' do
    file = Pathname(File.join(SPEC_DATA_VALID, 'options_in_file2.csv'))
    result = CSVDecision.parse(file, first_match: true, regexp_implicit: nil)

    expected = {
      first_match: false,
      regexp_implicit: true,
      text_only: false,
      index: nil,
      tables: nil,
      matchers: CSVDecision::DEFAULT_MATCHERS
    }
    expect(result.options).to eql expected
  end
end