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

    it 'makes correct decisions for a table with regexps and ranges' do
      data = <<~DATA
        in :age,   in :trait,  out :salesperson
        18..35,    maniac,      Adelsky
        23..35,    bad|maniac,  Bronco
        36..50,    bad.*,       Espadas
        51..78,    ,            Thorsten
        44..100,   !~ maniac,   Ojiisan
        > 100,     maniac.*,    Chester
        23..35,    .*rich,      Kerfelden
        ,          cheerful,    Swanson
        ,          maniac,      Korolev
      DATA
      table = CSVDecision.parse(data, regexp_implicit: true)

      expect(table.decide(age:  72)).to                     eq(salesperson: 'Thorsten')
      expect(table.decide(age:  25, trait: 'very rich')).to eq(salesperson: 'Kerfelden')
      expect(table.decide(age:  25, trait: 'maniac')).to    eq(salesperson: 'Adelsky')
      expect(table.decide(age:  44, trait: 'maniac')).to    eq(salesperson: 'Korolev')
      expect(table.decide(age: 101, trait: 'maniacal')).to  eq(salesperson: 'Chester')
      expect(table.decide(age:  45, trait: 'cheerful')).to  eq(salesperson: 'Ojiisan')
    end
  end
end