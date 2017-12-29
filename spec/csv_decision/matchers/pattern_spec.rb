# frozen_string_literal: true

require_relative '../../../lib/csv_decision'

describe CSVDecision::Matchers::Pattern do
  subject { described_class.new }

  describe '#new' do
    it { is_expected.to be_a CSVDecision::Matchers::Pattern }
    it { is_expected.to respond_to(:matches?).with(1).argument }
  end

  describe '#matches?' do
    context 'recognises regular expressions with implicit option' do
      matcher = described_class.new(regexp_implicit: true)

      expressions = [
        '!~Jerk',
        '!=Jerk',
        '=~ Jerk.+',
        'a.+c',
        '=~AB|BC|CD',
        'TRP\.CRD',
        '=~'
      ]

      expressions.each do |cell|
        it "recognises regexp #{cell}" do
          proc = matcher.matches?(cell)
          expect(proc).to be_a CSVDecision::Matchers::Proc
          expect(proc.type).to eq :proc
          expect(proc.function).to be_a ::Proc
          expect(proc.function.arity).to eq -1
        end
      end
    end

    context 'recognises regular expressions with explicit option' do
      matcher = described_class.new(regexp_implicit: true)

      expressions = [
        '!~Jerk',
        '!=Jerk',
        '=~ Jerk.+',
        '=~a.+c',
        '=~AB|BC|CD',
        '=~ TRP\.CRD'
      ]

      expressions.each do |cell|
        it "recognises regexp #{cell}" do
          proc = matcher.matches?(cell)
          expect(proc).to be_a CSVDecision::Matchers::Proc
          expect(proc.type).to eq :proc
          expect(proc.function).to be_a ::Proc
          expect(proc.function.arity).to eq -1
        end
      end
    end

    context 'matches regular expressions with implicit option' do
      matcher = described_class.new(regexp_implicit: true)

      expressions = [
        %w[!~Jerk        Jerks],
        %w[!=Jerk        Jerks],
          ['=~ Jerk.+', 'Jerks'],
        %w[a.+c          abc],
        %w[=~AB|BC|CD    CD],
        %w[TRP\.CRD      TRP.CRD],
        %w[=~            =~]
      ]

      expressions.each do |cell, value|
        it "matches regexp #{cell} to value #{value}" do
          proc = matcher.matches?(cell)
          expect(proc.function[value]).to be_truthy
        end
      end
    end

    context 'does not match regular expressions with implicit option' do
      matcher = described_class.new(regexp_implicit: true)

      expressions = [
        %w[!~Jerk      Jerk],
        %w[!=Jerk      Jerk],
        ['=~ Jerk.+', 'Jerk'],
        %w[a.+c        abcd],
        %w[=~AB|BC|CD  C],
        %w[TRP\.CRD    TRPxCRD]
      ]

      expressions.each do |cell, value|
        it "matches regexp #{cell} to value #{value}" do
          proc = matcher.matches?(cell)
          expect(proc.function[value]).to be_falsey
        end
      end
    end

    context 'matches regular expressions with explicit option' do
      matcher = described_class.new(regexp_implicit: false)

      expressions = [
        %w[!~Jerk      Jerks],
        %w[!=Jerk      Jerks],
        ['=~ Jerk.+', 'Jerks'],
        %w[=~a.+c      abc],
        %w[=~AB|BC|CD  CD],
        %w[=~TRP\.CRD  TRP.CRD]
      ]

      expressions.each do |cell, value|
        it "matches regexp #{cell} to value #{value}" do
          proc = matcher.matches?(cell)
          expect(proc.function[value]).to be_truthy
        end
      end
    end

    context 'does not match regular expressions with explicit option' do
      matcher = described_class.new(regexp_implicit: false)

      expressions = [
        %w[!~Jerk      Jerk],
        %w[!=Jerk      Jerk],
        ['=~ Jerk.+', 'Jerk'],
        %w[=~a.+c      abcd],
        %w[=~AB|BC|CD  C],
        %w[=~TRP\.CRD  TRPxCRD]
      ]

      expressions.each do |cell, value|
        it "matches regexp #{cell} to value #{value}" do
          proc = matcher.matches?(cell)
          expect(proc.function[value]).to be_falsey
        end
      end
    end

    context 'does not recognise non-regular expressions with implicit option' do
      matcher = described_class.new(regexp_implicit: true)

      expressions = [
        'Jerk',
        ':Jerk',
        '=~:Jerk',
        ':= nil',
        ':= 100.0'
      ]

      expressions.each do |cell|
        it "does not match string #{cell}" do
          proc = matcher.matches?(cell)
          expect(proc).to be_falsey
        end
      end
    end

    context 'does not recognise non-regular expressions with explicit option' do
      matcher = described_class.new(regexp_implicit: false)

      expressions = [
        'Jerk',
        ':Jerk',
        '=~:Jerk',
        'a.+c',
        '*.OPT.*',
        ':= nil',
        ':= 100.0',
        '=~'
      ]

      expressions.each do |cell|
        it "does not match string #{cell}" do
          proc = matcher.matches?(cell)
          expect(proc).to be_falsey
        end
      end
    end
  end
end