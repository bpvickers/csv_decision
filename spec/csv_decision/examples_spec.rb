# frozen_string_literal: true

require_relative '../../lib/csv_decision'

context 'simple examples' do
  context 'simple example - strings-only' do
    data = <<~DATA
      in :topic, in :region,  out :team_member
      sports,    Europe,      Alice
      sports,    ,            Bob
      finance,   America,     Charlie
      finance,   Europe,      Donald
      finance,   ,            Ernest
      politics,  Asia,        Fujio
      politics,  America,     Gilbert
      politics,  ,            Henry
      ,          ,            Zach
    DATA

    it 'makes correct decisions for CSV string' do
      table = CSVDecision.parse(data)

      result = table.decide(topic: 'finance', region: 'Europe')
      expect(result).to eq(team_member: 'Donald')

      result = table.decide(topic: 'sports', region: nil)
      expect(result).to eq(team_member: 'Bob')

      result = table.decide(topic: 'culture', region: 'America')
      expect(result).to eq(team_member: 'Zach')
    end

    it 'makes correct decisions for CSV file' do
      table = CSVDecision.parse(Pathname('spec/data/valid/simple_example.csv'))

      result = table.decide(topic: 'finance', region: 'Europe')
      expect(result).to eq(team_member: 'Donald')

      result = table.decide(topic: 'sports', region: nil)
      expect(result).to eq(team_member: 'Bob')

      result = table.decide(topic: 'culture', region: 'America')
      expect(result).to eq(team_member: 'Zach')
    end
  end

  context 'simple example - constants' do
    data = <<~DATA
      in :constant, out :type
      :=nil,        NilClass
      ==false,      FALSE
      =true,        TRUE
      = 0,          Zero
      :=100.0,      100%
    DATA

    it 'makes correct decisions for CSV string' do
      table = CSVDecision.parse(data)

      result = table.decide(constant: nil)
      expect(result).to eq(type: 'NilClass')

      result = table.decide(constant: true)
      expect(result).to eq(type: 'TRUE')

      result = table.decide(constant: false)
      expect(result).to eq(type: 'FALSE')

      result = table.decide(constant: 0)
      expect(result).to eq(type: 'Zero')

      result = table.decide(constant: BigDecimal.new('100.0'))
      expect(result).to eq(type: '100%')
    end
  end

  context 'simple example - symbols' do
    data = <<~DATA
      in :node, in :parent, out :top?
      ,          ==:node,   yes
      ,          ,          no
    DATA

    it 'makes correct decisions' do
      table = CSVDecision.parse(data)

      result = table.decide(node: 0, parent: 0)
      expect(result).to eq(top?: 'yes')

      result = table.decide(node: 1, parent: 0)
      expect(result).to eq(top?: 'no')

      result = table.decide(node: '0', parent: 0)
      expect(result).to eq(top?: 'no')
    end
  end

  context 'makes correct decision for table with symbol ordered compares' do
    data = <<~DATA
        in :traded, in :settled, out :status
        ,            :traded,    same day
        ,           >:traded,    pending
        ,           <:traded,    invalid trade
        ,                   ,    invalid data
    DATA

    it 'decides correctly' do
      table = CSVDecision.parse(data)

      expect(table.decide(traded: '20171227',  settled: '20171227')).to eq(status: 'same day')
      expect(table.decide(traded:  20171227,   settled:  20171227 )).to eq(status: 'same day')
      expect(table.decide(traded: '20171227',  settled: '20171228')).to eq(status: 'pending')
      expect(table.decide(traded:  20171227,   settled:  20171228 )).to eq(status: 'pending')
      expect(table.decide(traded: '20171228',  settled: '20171227')).to eq(status: 'invalid trade')
      expect(table.decide(traded:  20171228,   settled:  20171227 )).to eq(status: 'invalid trade')
      expect(table.decide(traded: '20171227',  settled:  20171228 )).to eq(status: 'invalid data')
    end
  end
end