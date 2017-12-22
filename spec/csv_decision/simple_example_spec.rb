# frozen_string_literal: true

require_relative '../../lib/csv_decision'

context 'simple example' do
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
