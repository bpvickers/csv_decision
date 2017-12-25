# frozen_string_literal: true

require_relative '../../../lib/csv_decision'

describe CSVDecision::Matchers::Symbol do
  subject { described_class.new }

  describe '#new' do
    it { is_expected.to be_a CSVDecision::Matchers::Symbol }
    it { is_expected.to be_a CSVDecision::Matchers::Matcher }
    it { is_expected.to respond_to(:matches?).with(1).argument }
  end

  context 'cell value recognition' do
    cells = {
      ':col' => { operator: nil, name: 'col' },
      '> :col' => { operator: '>', name: 'col' },
      '= :col' => { operator: '=', name: 'col' },
      '<= :col' => { operator: '<=', name: 'col' }
    }
    cells.each_pair do |cell, expected|
      it "recognises #{cell} as a constant" do
        match = CSVDecision::Symbol::SYMBOL_COMPARE_RE.match(cell)
        expect(match['comparator']).to eq expected[:operator]
        expect(match['name']).to eq expected[:name]
      end
    end
  end

  describe '#matches?' do
    matcher = described_class.new

    context 'symbol expression matches value to hash data' do
      examples = [
        { cell:  ':col',   value:  0,  hash: { col:  0 },  result: true },
        { cell:  ':col',   value: '0', hash: { col: '0' }, result: true },
        { cell:  ':col',   value:  0,  hash: { col: '0' }, result: false },
        { cell:  ':col',   value: '0', hash: { col:  0 },  result: false },
        { cell:  ':col',   value:  1,  hash: { col:  0 },  result: false },
        { cell:  ':key',   value:  0,  hash: { col:  0 },  result: false },
        { cell: '!=:col',  value:  0,  hash: { col:  0 },  result: false },
        { cell: '!=:col',  value: '0', hash: { col: '0' }, result: false },
        { cell: '!=:col',  value:  0,  hash: { col: '0' }, result: true },
        { cell: '!=:col',  value: '0', hash: { col:  0 },  result: true },
        { cell: '!=:col',  value:  1,  hash: { col:  0 },  result: true },
        { cell: '!=:key',  value:  0,  hash: { col:  0 },  result: true },
        { cell:  '>:col',  value:  1,  hash: { col:  0 },  result: true },
        { cell:  '>:col',  value:  0,  hash: { col:  1 },  result: false },
        { cell:  '<:col',  value:  0,  hash: { col:  1 },  result: true },
        { cell:  '<:col',  value:  1,  hash: { col:  0 },  result: false },
        { cell:  '= :col', value:  0,  hash: { col:  0 },  result: true },
        { cell:  '==:col', value:  0,  hash: { col:  0 },  result: true },
        { cell:  ':=:col', value:  0,  hash: { col:  0 },  result: true },
        { cell:  '= :col', value: '0', hash: { col:  0 },  result: false },
        { cell:  '>=:col', value:  1,  hash: { col:  0 },  result: true },
        { cell:  '>=:col', value:  0,  hash: { col:  1 },  result: false },
        { cell:  '<=:col', value:  0,  hash: { col:  1 },  result: true },
        { cell:  '<=:col', value:  1,  hash: { col:  0 },  result: false },
        { cell:  '<=:col', value: '1', hash: { col:  1 },  result: false },
      ]

      examples.each do |ex|
        it "cell #{ex[:cell]} matches value: #{ex[:value]} to hash: #{ex[:hash]}" do
          proc = matcher.matches?(ex[:cell])
          expect(proc).to be_a(CSVDecision::Proc)
          expect(proc.function.call(ex[:value], ex[:hash])).to eq ex[:result]
        end
      end
    end

    context 'does not match a function' do
      data = ['1', 'abc', 'abc.*def', '-1..1', '0...3', ':= false', ':= lookup?']

      data.each do |cell|
        it "cell #{cell} is not a function" do
          expect(matcher.matches?(cell)).to eq false
        end
      end
    end
  end
end