# frozen_string_literal: true

context 'use of formatters to format output column values' do
  module TestFormatter
    def self.format(value:, format:)
      return nil unless value.is_a?(String)
      return nil unless format.is_a?(Integer)

      value[0..format - 1]
    end
  end

  context 'use of formatters with first_match: option' do
    examples = [
      {
        example: 'evaluates format column on output value and then if condition',
        options: { first_match: true },
        data: <<~DATA
          out :value, format:value, out: len,      if:
          :type_cd,   := 3,         :value.length, :len == 3
        DATA
      },
      {
        example: 'evaluates format column on output value',
        options: { first_match: true },
        data: <<~DATA
          out :value, format:value, out: len
          :type_cd,   := 3,         :value.length
        DATA
      }
    ]

    describe CSVDecision::Table do
      examples.each do |test|
        table = CSVDecision.parse(test[:data], formatter: TestFormatter)

        %i[decide decide!].each do |method|
          it "#{method} correctly #{test[:example]}" do

            expect(table.decide(type_cd: '1234'))
              .to eq(:'format:value' => 3, value: '123', len: 3)
          end
        end
      end
    end
  end

  context 'use of formatters with accumulate option' do
    examples = [
      {
        example: 'evaluates format column on output value and then if condition',
        options: { first_match: true },
        data: <<~DATA
          out :value, format:value, out: len,      if:
          :type_cd,   := 3,         :value.length, :len == 3
          :cusip,     := 8,         :value.length, :len == 8
        DATA
      },
      {
        example: 'evaluates format column on output value',
        options: { first_match: true },
        data: <<~DATA
          out :value, format:value, out: len
          :type_cd,   := 3,         :value.length
          :cusip,     := 8,         :value.length
        DATA
      }
    ]

    describe CSVDecision::Table do
      examples.each do |test|
        table = CSVDecision.parse(test[:data], formatter: TestFormatter, first_match: false)

        %i[decide decide!].each do |method|
          it "#{method} correctly #{test[:example]}" do

            expect(table.decide(type_cd: '1234', cusip: '123456789'))
              .to eq(value: %w[123 12345678], :'format:value' => [3, 8], len:  [3, 8])
          end
        end
      end
    end
  end
end