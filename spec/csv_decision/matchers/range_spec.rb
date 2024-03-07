# frozen_string_literal: true

require_relative '../../../lib/csv_decision'

describe CSVDecision::Matchers::Range do
  subject { described_class.new }

  describe '#new' do
    it { is_expected.to be_a CSVDecision::Matchers::Range }
    it { is_expected.to respond_to(:matches?).with(1).argument }
  end

  describe '#matches?' do
    matcher = described_class.new

    context 'range matches value' do
      data = [
          [ '-1..+4', 0],
          ['!-1..+4', 5],
          ['1.1...4', 3],
        %w[a..z       a],
        %w[a..z       z],
        %w[a..z       m],
        %w[!-1..1     1.1],
          ['! -1..1', BigDecimal('1.1')],
          [  '-1..1', BigDecimal('1')]
      ]

      data.each do |cell, value|
        it "range #{cell} matches #{value}" do
          proc = matcher.matches?(cell)
          expect(proc).to be_a(CSVDecision::Matchers::Proc)
          expect(proc.type).to eq :proc
          expect(proc.function[value]).to eq true
        end
      end
    end

    context 'range does not match value' do
      data = [
        [ '-1..+4', 5],
        ['!-1..+4', 2],
        %w[a...z      z],
        %w[!a..z      m],
        %w[-1..1     1.1],
        ['-1..1', BigDecimal('1.1')],
        ['-1..1', BigDecimal('1.1')]
      ]

      data.each do |cell, value|
        it "range #{cell} does not match #{value}" do
          proc = matcher.matches?(cell)
          expect(proc).to be_a(CSVDecision::Matchers::Proc)
          expect(proc.type).to eq :proc
          expect(proc.function[value]).to eq false
        end
      end
    end

    context 'does not match a range' do
      data = ['1', ':column', ':= nil', ':= true', 'abc', 'abc.*def']

      data.each do |cell|
        it "cell #{cell} is not a range}" do
          expect(matcher.matches?(cell)).to eq false
        end
      end
    end
  end
end
