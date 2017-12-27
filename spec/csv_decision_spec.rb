# frozen_string_literal: true

describe CSVDecision do
  describe '.root' do
    specify { expect(CSVDecision.root).to eq File.dirname __dir__ }
  end
end