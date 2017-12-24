# frozen_string_literal: true

require_relative '../../../lib/csv_decision'

describe CSVDecision::Matchers::Function do
  subject { described_class.new }

  describe '#new' do
    it { is_expected.to be_a CSVDecision::Matchers::Function }
    it { is_expected.to be_a CSVDecision::Matchers::Matcher }
    it { is_expected.to respond_to(:matches?).with(1).argument }
  end

  context 'cell value recognition' do
    cells = {
      ':= nil' => { operator: ':=', name: 'nil'},
      '== nil' => { operator: '==', name: 'nil'},
      '=  nil' => { operator: '=', name: 'nil' },
      '==true' => { operator: '==', name: 'true' },
      ':=false' => { operator: ':=', name: 'false' },
      '=false' => { operator: '=', name: 'false' },
      ':false' => { operator: ':', name: 'false' },
      '> :col' => { operator: '>', name: ':', args: 'col' },
      '= :col' => { operator: '=', name: ':', args: 'col' },
      '<= :col' => { operator: '<=', name: ':', args: 'col' },
      ':=function' => { operator: ':=', name: 'function' },
      ':=function()' => { operator: ':=', name: 'function', args:'()' },
      ':=function(arg: value)' => { operator: ':=', name: 'function', args:'(arg: value)' },
      ':= !function(arg: value)' => { operator: ':=', negate: '!', name: 'function', args:'(arg: value)' },
      '== ! func(arg: val)' => { operator: '==', negate: '!', name: 'func', args:'(arg: val)' },
    }
    cells.each_pair do |cell, expected|
      it "recognises #{cell} as a constant" do
        match = described_class::FUNCTION_RE.match(cell)
        expect(match['operator']).to eq expected[:operator]
        expect(match['name']).to eq expected[:name]
        expect(match['negate']).to eq expected[:negate] || ''
        expect(match['args']).to eq expected[:args] || ''
      end
    end
  end

  describe '#matches?' do
    matcher = described_class.new

    context 'constant matches value' do
      data = [
        ['= nil', nil],
        [':= false', false],
        ['==true', true]
      ]

      data.each do |cell, value|
        it "comparision #{cell} matches #{value}" do
          proc = matcher.matches?(cell)
          expect(proc).to be_a(CSVDecision::Proc)
          expect(proc.type).to eq :constant
          expect(proc.function).to eq value
        end
      end
    end

    context 'function matches signature' do
      data = [
        ['= nil', nil],
        [':= false', false],
        ['==true', true]
      ]

      data.each do |cell, value|
        it "comparision #{cell} matches #{value}" do
          proc = matcher.matches?(cell)
          expect(proc).to be_a(CSVDecision::Proc)
          expect(proc.type).to eq :constant
          expect(proc.function).to eq value
        end
      end
    end

    context 'does not match a function constant' do
      data = ['1', ':column', ':= 1.1', ':= abc', 'abc', 'abc.*def', '-1..1', '0...3']

      data.each do |cell|
        it "cell #{cell} is not a comparision}" do
          expect(matcher.matches?(cell)).to eq false
        end
      end
    end
  end
end