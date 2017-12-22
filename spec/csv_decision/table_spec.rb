# frozen_string_literal: true

require_relative '../../lib/csv_decision'

SPEC_DATA_VALID ||= File.join(CSVDecision.root, 'spec', 'data', 'valid')

describe CSVDecision::Table do
  describe '#decide' do
    context 'makes correct decisions for simple, text-only tables' do
      examples = [
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
            ['sports',    'Europe',     'Alice'],
            ['sports',    '',           'Bob'],
            ['finance',   'America',    'Charlie'],
            ['finance',   'Europe',     'Donald'],
            ['finance',   '',           'Ernest'],
            ['politics',  'Asia',       'Fujio'],
            ['politics',  'America',    'Gilbert'],
            ['politics',   '',          'Henry'],
            ['',           '',          'Zach']
          ]
        },
      ]
      examples.each do |test|
        %i[decide decide!].each do |method|
          it "#{method} correctly #{test[:example]}" do
            table = CSVDecision.parse(test[:data], test[:options])

            expect(table.send(method, topic: 'finance', region: 'Europe')).to eq(team_member: 'Donald')
            expect(table.send(method, topic: 'sports',  region: nil)).to eq(team_member: 'Bob')
            expect(table.send(method, topic: 'culture', region: 'America')).to eq(team_member: 'Zach')
          end
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
            23..40,    bad|maniac,  Bronco
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
            23..40,    =~ bad|maniac, Bronco
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
            >= 23,    <= 40,   =~ bad|maniac, Bronco
            >= 36,    <= 50,   =~ bad.*,      Espadas
            >= 51,    <= 78,   ,              Thorsten
            >= 44,    <= 100,  != maniac,     Ojiisan
            > 100,    ,        =~ maniac.*,   Chester
            >= 23,    <= 35,   =~ .*rich,     Kerfelden
            ,         ,        cheerful,      Swanson
            ,         ,        maniac,        Korolev
          DATA
        },
      ]
      examples.each do |test|
        %i[decide decide!].each do |method|
          it "#{method} correctly uses #{test[:example]}" do
            table = CSVDecision.parse(test[:data], test[:options])

            expect(table.send(method, age:  72)).to eq(salesperson: 'Thorsten')
            expect(table.send(method, age:  25, trait: 'very rich')).to eq(salesperson: 'Kerfelden')
            expect(table.send(method, age:  25, trait: 'maniac')).to eq(salesperson: 'Adelsky')
            expect(table.send(method, age:  44, trait: 'maniac')).to eq(salesperson: 'Korolev')
            expect(table.send(method, age: 101, trait: 'maniacal')).to eq(salesperson: 'Chester')
            expect(table.send(method, age:  45, trait: 'cheerful')).to eq(salesperson: 'Ojiisan')
            expect(table.send(method, age:  49, trait: 'bad')).to eq(salesperson: 'Espadas')
            expect(table.send(method, age:  40, trait: 'maniac')).to eq(salesperson: 'Bronco')
          end
        end
      end
    end
  end
end