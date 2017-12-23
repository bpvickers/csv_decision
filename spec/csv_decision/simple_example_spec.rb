# frozen_string_literal: true

require_relative '../../lib/csv_decision'

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

