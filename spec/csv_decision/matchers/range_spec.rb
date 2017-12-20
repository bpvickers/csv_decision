# frozen_string_literal: true

require_relative '../../../lib/csv_decision'

describe CSVDecision::Matchers::Range do
  subject { described_class.new }

  describe '#new' do
    it { is_expected.to be_a CSVDecision::Matchers::Range }
    it { is_expected.to respond_to(:matches?).with(1).argument }
  end

  context 'cell value recognition' do
    it 'recognises various numeric range cell values' do
      ranges = {
        '-1..1' => { min: '-1', type: '..', max: '1', negate: '' },
        '! -1..1' => { min: '-1', type: '..', max: '1', negate: '!' },
        '!-1.0..1.1' => { min: '-1.0', type: '..', max: '1.1', negate: '!' },
        '!-1.0...1.1' => { min: '-1.0', type: '...', max: '1.1', negate: '!' }
      }
      ranges.each_pair do |range, expected|
        match = described_class::NUMERIC_RANGE.match(range)
        expect(match['min']).to eq expected[:min]
        expect(match['max']).to eq expected[:max]
        expect(match['type']).to eq expected[:type]
        expect(match['negate']).to eq expected[:negate]
      end
    end

    it 'recognises various alphanumeric range cell values' do
      ranges = {
        'a..z' => { min: 'a', type: '..', max: 'z', negate: '' },
        '!1...9' => { min: '1', type: '...', max: '9', negate: '!' },
      }
      ranges.each_pair do |range, expected|
        match = described_class::ALNUM_RANGE.match(range)
        expect(match['min']).to eq expected[:min]
        expect(match['max']).to eq expected[:max]
        expect(match['type']).to eq expected[:type]
        expect(match['negate']).to eq expected[:negate]
      end
    end
  end

  context 'range construction' do
    it 'constructs various numeric ranges' do
      ranges = {
        '-1..1' => { range: -1..1, negate: false },
        '! -1..1' => { range: -1..1, negate: true },
        '!-1.0..1.1' => { range: BigDecimal.new('-1.0')..BigDecimal.new('1.1'), negate: true },
        '!-1.0...1' => { range: BigDecimal.new('-1.0')...1, negate: true }
      }
      ranges.each_pair do |cell, expected|
        match = described_class::NUMERIC_RANGE.match(cell)
        negate, range = CSVDecision::Matchers::Range.range(match, coerce: :to_numeric)
        expect(negate).to eq expected[:negate]
        expect(range).to eq expected[:range]
      end
    end

    it 'constructs various alphanumeric ranges' do
      ranges = {
        'a..z' => { range: 'a'..'z', negate: false },
        '!1...9' => { range: '1'...'9', negate: true },
      }
      ranges.each_pair do |cell, expected|
        match = described_class::ALNUM_RANGE.match(cell)
        negate, range = described_class.range(match)
        expect(negate).to eq expected[:negate]
        expect(range).to eq expected[:range]
      end
    end
  end

  describe '#matches?' do

  end
end