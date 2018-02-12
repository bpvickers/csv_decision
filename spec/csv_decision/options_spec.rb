# frozen_string_literal: true

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
      matchers: CSVDecision::Options::DEFAULT_MATCHERS
    }
    expect(result.options).to eql expected
  end

  it 'overrides the default options' do
    data = <<~DATA
      IN :input, OUT :output
      input0,    output0
    DATA

    result = CSVDecision.parse(data,
                               first_match: false,
                               matchers: [CSVDecision::Matchers::Pattern])

    expected = {
      first_match: false,
      regexp_implicit: false,
      text_only: false,
      matchers: [CSVDecision::Matchers::Pattern]
    }
    expect(result.options).to eql expected
  end

  it 'rejects an invalid option argument' do
    data = <<~DATA
      IN :input, OUT :output
      input0,    output0
    DATA

    expect { CSVDecision.parse(data, bad_option: false) }
      .to raise_error(CSVDecision::CellValidationError,
                      "invalid option(s) supplied: [:bad_option]")
  end

  it 'parses options from a CSV file' do
    file = Pathname(File.join(SPEC_DATA_VALID, 'options_in_file1.csv'))
    result = CSVDecision.parse(file)

    expected = {
      first_match: false,
      regexp_implicit: false,
      text_only: false,
      matchers: CSVDecision::Options::DEFAULT_MATCHERS
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
      matchers: CSVDecision::Options::DEFAULT_MATCHERS
    }
    expect(result.options).to eql expected
  end

  it 'parses index option from the CSV file' do
    file = Pathname(File.join(SPEC_DATA_VALID, 'options_in_file3.csv'))
    result = CSVDecision.parse(file)

    expected = {
      first_match: false,
      regexp_implicit: true,
      text_only: false,
      matchers: CSVDecision::Options::DEFAULT_MATCHERS
    }
    expect(result.options).to eql expected
  end
end