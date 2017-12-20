# frozen_string_literal: true

require_relative '../../lib/csv_decision'

describe CSVDecision::Table do
  describe '#decide' do
    it 'makes correct decisions for a simple text-only table' do
      data = <<~DATA
        in :topic, in :region,  out :team member
        sports,    Europe,      Alice
        sports,    ,            Bob
        finance,   America,     Charlie
        finance,   Europe,      Donald
        finance,   ,            Ernest
        politics,  Asia,        Fujio
        politics,  Americas,    Gilbert
        politics,  ,            Henry
        ,          ,            Zach
      DATA
      table = CSVDecision.parse(data)

      expect(table.decide(topic: 'finance', region: 'Europe')).to     eq(team_member: 'Donald')
      expect(table.decide(topic: 'sports',  region: nil)).to          eq(team_member: 'Bob')
      expect(table.decide(topic: 'culture', region: 'America')).to    eq(team_member: 'Zach')
    end
  end
end