# frozen_string_literal: true

require_relative '../../../lib/csv_decision'

describe CSVDecision::Matchers::Guard do
  subject { described_class.new }

  describe '#new' do
    it { is_expected.to be_a CSVDecision::Matchers::Guard }
    it { is_expected.to be_a CSVDecision::Matchers::Matcher }
    it { is_expected.to respond_to(:matches?).with(1).argument }
  end

  describe '#matches?' do
    matcher = described_class.new

    context 'symbol expression matches value to hash data' do
      examples = [
        # Integer equality
        { cell: ':col == 0',   hash: { col:   0  }, result: true },
        { cell: ':col == 0',   hash: { col:  '0' }, result: true },
        { cell: ':col == 0',   hash: { col:   1 },  result: false },
        { cell: ':col == 0',   hash: { col:  '1' }, result: false },
        { cell: ':col == 0',   hash: { col:  nil }, result: false },
        # Integer inequality
        { cell: ':col != 0',   hash: { col:   0  }, result: false },
        { cell: ':col != 0',   hash: { col:  '0' }, result: false },
        { cell: ':col != 0',   hash: { col:   1 },  result: true },
        { cell: ':col != 0',   hash: { col:  '1' }, result: true },
        { cell: ':col != 0',   hash: { col:  nil }, result: true },
        # Kind of silly, but valid
        { cell: '!:col = 0',   hash: { col:   0  }, result: false },
        { cell: '!:col = 0',   hash: { col:  '0' }, result: false },
        { cell: '!:col = 0',   hash: { col:   1 },  result: true },
        { cell: '!:col = 0',   hash: { col:  '1' }, result: true },
        { cell: '!:col = 0',   hash: { col:  nil }, result: true },
        # Integer compare
        { cell: ':col > 0',   hash: { col:   0  }, result: false },
        { cell: ':col > 0',   hash: { col:  '0' }, result: false },
        { cell: ':col > 0',   hash: { col:   1 },  result: true },
        { cell: ':col > 0',   hash: { col:  '1' }, result: true },
        { cell: ':col > 0',   hash: { col:  nil }, result: nil },
        # BigDecimal equality
        { cell: ':col == 0.0', hash: { col: BigDecimal('0.0') }, result: true },
        { cell: ':col == 0.0', hash: { col: '0.0' },             result: true },
        { cell: ':col == 0.0', hash: { col:  0  },               result: true },
        { cell: ':col == 0.0', hash: { col: '0' },               result: true },
        { cell: ':col == 0.0', hash: { col: '0.1' },             result: false },
        { cell: ':col == 0.0', hash: { col:  0.0 },              result: false },
        { cell: ':col == 0.0', hash: { col:  nil },              result: false },
        # BigDecimal inequality
        { cell: ':col != 0.0', hash: { col: BigDecimal('0.0') }, result: false },
        { cell: ':col != 0.0', hash: { col: '0.0' },             result: false },
        { cell: ':col != 0.0', hash: { col:  0  },               result: false },
        { cell: ':col != 0.0', hash: { col: '0' },               result: false },
        { cell: ':col != 0.0', hash: { col: '0.1' },             result: true },
        { cell: ':col != 0.0', hash: { col:  0.0 },              result: true },
        { cell: ':col != 0.0', hash: { col:  nil },              result: true },
        # String compare
        { cell: ':col > m',   hash: { col:   0  }, result: nil },
        { cell: ':col > m',   hash: { col:  'a' }, result: false },
        { cell: ':col > m',   hash: { col:  'n' }, result: true },
        { cell: ':col > m',   hash: { col:  nil }, result: nil },
        # String compare
        { cell: ':col < m',   hash: { col:   0  }, result: nil },
        { cell: ':col < m',   hash: { col:  'a' }, result: true },
        { cell: ':col < m',   hash: { col:  'n' }, result: false },
        { cell: ':col < m',   hash: { col:  nil }, result: nil },
        # Method calls
        { cell:   ':col.nil?',   hash: { col:  nil },  result: true },
        { cell:   ':col.nil?',   hash: { col:  0 },    result: false },
        { cell:  '!:col.nil?',   hash: { col:  nil },  result: false },
        { cell:  '!:col.nil?',   hash: { col:  0 },    result: true },
        { cell:   ':col.upcase', hash: { col:  'u' },  result: 'U' },
        { cell:   ':col.next',   hash: { col:  -1 },   result: 0 },
        { cell:   ':col.first',  hash: { col:  '98' }, result: '9' },
        { cell:   ':col.last',   hash: { col:  '98' }, result: '8' },
        { cell:   ':col.zero?',  hash: { col:  0 },    result: true },
        { cell:   ':col.zero?',  hash: { col:  nil },  result: false }
      ]

      examples.each do |ex|
        it "cell #{ex[:cell]} matches value: #{ex[:value]} to hash: #{ex[:hash]}" do
          proc = matcher.matches?(ex[:cell])
          expect(proc).to be_a(CSVDecision::Proc)
          expect(proc.type).to eq :guard
          expect(proc.function.call(ex[:hash])).to eq ex[:result]
        end
      end
    end

    context 'does not match a non-function string' do
      data = ['1', 'abc', 'abc.*def', '-1..1', '0...3', ':= true', ':= lookup(:table)', '>= :col', ':col']

      data.each do |cell|
        it "cell #{cell} is not a function" do
          expect(matcher.matches?(cell)).to eq false
        end
      end
    end
  end
end