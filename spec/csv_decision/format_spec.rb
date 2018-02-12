# frozen_string_literal: true

context 'use of formatters to format output column values' do
  module TestFormatter
    def self.format(value:, format:)
      return nil unless value.is_a?(String)
      return nil unless format.is_a?(Integer)

      value[0..format - 1]
    end
  end

  data = <<~DATA
    out :value, format:value, out.len,       if:
    :type_cd,   := 3,         :value.length :len == 3
  DATA

  describe CSVDecision::Table do
    describe '.parse' do
      xit 'it accepts a valid formatter parameter' do
        expect { CSVDecision.parse(data, formatter: TestFormatter) }.not_to raise_error
      end
    end

    describe '#decide' do
      xit 'uses the formatter to format the output' do
        table = CSVDecision.parse(data, formatter: TestFormatter)

        expect(table.decide(type_cd: '1234')).to eq(value: '123')
      end
    end
  end
end