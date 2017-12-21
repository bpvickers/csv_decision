# frozen_string_literal: true

require_relative '../../lib/csv_decision'

SPEC_DATA_VALID ||= File.join(CSVDecision.root, 'spec', 'data', 'valid')

describe CSVDecision::Table do
  describe '#decide' do
    context 'makes correct decisions for simple, text-only tables' do
      examples = [
        {
          example: 'parses CSV string',
          options: {},
          data: <<~DATA
            in :topic, in :region,  out :team member
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
        },
        {
          example: 'parses CSV file',
          options: {},
          data: Pathname(File.join(SPEC_DATA_VALID, 'simple_example.csv'))
        },
        {
          example: 'parses data array',
          options: {},
          data: [
            ['in :topic', 'in :region', 'out :team member'],
            ['sports',   'Europe',   'Alice'],
            ['sports',   '',         'Bob'],
            ['finance',  'America',  'Charlie'],
            ['finance',  'Europe',   'Donald'],
            ['finance',  '',         'Ernest'],
            ['politics', 'Asia',     'Fujio'],
            ['politics', 'America',  'Gilbert'],
            ['politics', '',         'Henry'],
            ['',         '',         'Zach']
          ]
        },
      ]
      examples.each do |test|
        it "correctly #{test[:example]}" do
          table = CSVDecision.parse(test[:data], test[:options])

          expect(table.decide(topic: 'finance', region: 'Europe')).to eq(team_member: 'Donald')
          expect(table.decide(topic: 'sports',  region: nil)).to eq(team_member: 'Bob')
          expect(table.decide(topic: 'culture', region: 'America')).to eq(team_member: 'Zach')
        end
      end
    end

    context 'makes correct decisions for a table with regexps and ranges' do
      examples = [
        {
          example: 'implicit regular expressions',
          options: { regexp_implicit: true },
          data: <<~DATA
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
        },
        {
          example: 'explicit regular expressions',
          options: { regexp_implicit: false },
          data: <<~DATA
            in :age,   in :trait,     out :salesperson
            18..35,    maniac,        Adelsky
            23..35,    =~ bad|maniac, Bronco
            36..50,    =~ bad.*,      Espadas
            51..78,    ,              Thorsten
            44..100,   !~ maniac,     Ojiisan
            > 100,     =~ maniac.*,   Chester
            23..35,    =~ .*rich,     Kerfelden
            ,          cheerful,      Swanson
            ,          maniac,        Korolev
          DATA
        },
        {
          example: 'multiple in column references',
          options: { regexp_implicit: false },
          data: <<~DATA
            in :age,  in :age, in :trait,     out :salesperson
            >= 18,    <= 35,   maniac,        Adelsky
            >= 23,    <= 35,   =~ bad|maniac, Bronco
            >= 36,    <= 50,   =~ bad.*,      Espadas
            >= 51,    <= 78,   ,              Thorsten
            >= 44,    <= 100,  !~ maniac,     Ojiisan
            > 100,    ,        =~ maniac.*,   Chester
            >= 23,    <= 35,   =~ .*rich,     Kerfelden
            ,         ,        cheerful,      Swanson
            ,         ,        maniac,        Korolev
          DATA
        },
      ]
      examples.each do |test|
        it "correctly uses #{test[:example]}" do
          table = CSVDecision.parse(test[:data], test[:options])

          expect(table.decide(age:  72)).to eq(salesperson: 'Thorsten')
          expect(table.decide(age:  25, trait: 'very rich')).to eq(salesperson: 'Kerfelden')
          expect(table.decide(age:  25, trait: 'maniac')).to    eq(salesperson: 'Adelsky')
          expect(table.decide(age:  44, trait: 'maniac')).to    eq(salesperson: 'Korolev')
          expect(table.decide(age: 101, trait: 'maniacal')).to  eq(salesperson: 'Chester')
          expect(table.decide(age:  45, trait: 'cheerful')).to  eq(salesperson: 'Ojiisan')
        end
      end
    end
  end
end