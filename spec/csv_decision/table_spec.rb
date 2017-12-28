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
          it "#{method} correctly #{test[:example]} with first_match: true" do
            options = test[:options].merge(first_match: true)
            table = CSVDecision.parse(test[:data], options)

            expect(table.send(method, topic: 'finance', region: 'Europe')).to eq(team_member: 'Donald')
            expect(table.send(method, topic: 'sports',  region: nil)).to eq(team_member: 'Bob')
            expect(table.send(method, topic: 'culture', region: 'America')).to eq(team_member: 'Zach')
          end

          it "#{method} correctly #{test[:example]} with first_match: false" do
            options = test[:options].merge(first_match: false)
            table = CSVDecision.parse(test[:data], options)

            expect(table.send(method, topic: 'finance', region: 'Europe'))
              .to eq(team_member: %w[Donald Ernest Zach])
            expect(table.send(method, topic: 'sports',  region: nil))
              .to eq(team_member: %w[Bob Zach])
            expect(table.send(method, topic: 'culture', region: 'America'))
              .to eq(team_member: 'Zach')
          end
        end
      end
    end

    context 'makes correct decisions for simple non-string constants' do
      examples = [
        {
          example: 'parses CSV file',
          options: {},
          data: Pathname(File.join(SPEC_DATA_VALID, 'simple_constants.csv'))
        },
        {
          example: 'parses CSV string',
          options: {},
          data: <<~DATA
            in :constant, out :type
            :=nil,        :=nil
            = 0,          = 0
            :=100.0,      :=100
            ,             Unrecognized
          DATA
        },
      ]
      examples.each do |test|
        %i[decide decide!].each do |method|
          it "#{method} correctly #{test[:example]} with first_match: true" do
            options = test[:options].merge(first_match: true)
            table = CSVDecision.parse(test[:data], options)

            expect(table.send(method, constant: nil)).to eq(type: nil)
            expect(table.send(method, constant: 0)).to eq(type: 0)
            expect(table.send(method, constant: BigDecimal.new('100.0'))).to eq(type: BigDecimal('100.0'))
            expect(table.send(method, constant: ':=nil')).to eq(type: 'Unrecognized')
            expect(table.send(method, constant: '= 0')).to eq(type: 'Unrecognized')
            expect(table.send(method, constant: ':=100.0')).to eq(type: 'Unrecognized')
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
            := 100,    ,            Thorsten
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
            ==100,     ,              Thorsten
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
            == 100,   ,        ,              Thorsten
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
          it "#{method} correctly uses #{test[:example]} with first_match: true" do
            options = test[:options].merge(first_match: true)
            table = CSVDecision.parse(test[:data], options)

            expect(table.send(method, age: 100)).to eq(salesperson: 'Thorsten')
            expect(table.send(method, age:  25, trait: 'very rich')).to eq(salesperson: 'Kerfelden')
            expect(table.send(method, age:  25, trait: 'maniac')).to eq(salesperson: 'Adelsky')
            expect(table.send(method, age:  44, trait: 'maniac')).to eq(salesperson: 'Korolev')
            expect(table.send(method, age: 101, trait: 'maniacal')).to eq(salesperson: 'Chester')
            expect(table.send(method, age:  44, trait: 'cheerful')).to eq(salesperson: 'Ojiisan')
            expect(table.send(method, age:  49, trait: 'bad')).to eq(salesperson: 'Espadas')
            expect(table.send(method, age:  40, trait: 'maniac')).to eq(salesperson: 'Bronco')
          end

          it "#{method} correctly uses #{test[:example]} with first_match: false" do
            options = test[:options].merge(first_match: false)
            table = CSVDecision.parse(test[:data], options)

            expect(table.send(method, age: 100))
              .to eq(salesperson: %w[Thorsten Ojiisan])
            expect(table.send(method, age:  25, trait: 'very rich'))
              .to eq(salesperson: 'Kerfelden')
            expect(table.send(method, age:  25, trait: 'maniac'))
              .to eq(salesperson: %w[Adelsky Bronco Korolev])
            expect(table.send(method, age:  44, trait: 'maniac'))
              .to eq(salesperson: 'Korolev')
            expect(table.send(method, age: 101, trait: 'maniacal'))
              .to eq(salesperson: 'Chester')
            expect(table.send(method, age:  45, trait: 'cheerful'))
              .to eq(salesperson: %w[Ojiisan Swanson])
            expect(table.send(method, age:  49, trait: 'bad'))
              .to eq(salesperson: %w[Espadas Ojiisan])
            expect(table.send(method, age:  40, trait: 'maniac'))
              .to eq(salesperson: %w[Bronco Korolev])
          end
        end
      end
    end

    context 'makes correct decision for table with symbol equality compares' do
      examples = [
        { example: 'uses == :node',
          options: {},
          data: <<~DATA
            in :node, in :parent, out :top?
            ,          ==:node,   yes
            ,          ,          no
          DATA
        },
        { example: 'uses :node',
          options: {},
          data: <<~DATA
            in :node, in :parent, out :top?
            ,         :node,      yes
            ,         ,           no
          DATA
        },
        { example: 'uses := :node',
          options: {},
          data: <<~DATA
            in :node, in :parent, out :top?
            ,         := :node,   yes
            ,         ,           no
          DATA
        },
        { example: 'uses = :node',
          options: {},
          data: <<~DATA
            in :node, in :parent, out :top?
            ,         = :node,    yes
            ,         ,           no
          DATA
        },
        { example: 'uses :node, drops :node input column',
          options: {},
          data: <<~DATA
            in :parent, out :top?
            :node,      yes
            ,           no
          DATA
        },
        { example: 'uses :parent, drops :parent input column',
          options: {},
          data: <<~DATA
            in :node, out :top?
            :parent,  yes
            ,         no
          DATA
        },
        { example: 'uses != :parent, drops :parent input column',
          options: {},
          data: <<~DATA
            in :node,    out :top?
            != :parent,  no
            ,            yes
          DATA
        }
      ]

      examples.each do |test|
        %i[decide decide!].each do |method|
          it "#{method} correctly #{test[:example]}" do
            options = test[:options]
            table = CSVDecision.parse(test[:data], options)

            expect(table.send(method, node:  0,  parent: 0)).to eq(top?: 'yes')
            expect(table.send(method, node:  1,  parent: 0)).to eq(top?: 'no')
            expect(table.send(method, node: '0', parent: 0)).to eq(top?: 'no')
          end
        end
      end
    end

    context 'makes correct decision for table with symbol ordered compares' do
      examples = [
        { example: 'uses == :node',
          options: {},
          data: <<~DATA
            in :traded, in :settled, out :status
            ,            :traded,    same day
            ,           >:traded,    pending
            ,           <:traded,    invalid trade
            ,                   ,    invalid data
          DATA
        },
      ]
      examples.each do |test|
        %i[decide decide!].each do |method|
          it "#{method} correctly #{test[:example]}" do
            table = CSVDecision.parse(test[:data], test[:options])

            expect(table.send(method, traded: '20171227',  settled: '20171227')).to eq(status: 'same day')
            expect(table.send(method, traded:  20171227,   settled:  20171227 )).to eq(status: 'same day')
            expect(table.send(method, traded: '20171227',  settled: '20171228')).to eq(status: 'pending')
            expect(table.send(method, traded:  20171227,   settled:  20171228 )).to eq(status: 'pending')
            expect(table.send(method, traded: '20171228',  settled: '20171227')).to eq(status: 'invalid trade')
            expect(table.send(method, traded:  20171228,   settled:  20171227 )).to eq(status: 'invalid trade')
            expect(table.send(method, traded: '20171227',   settled: 20171228 )).to eq(status: 'invalid data')
          end
        end
      end
    end

    context 'makes correct decisions for table with column symbol guards' do
      examples = [
        { example: 'evaluates guard conditions & output functions',
          options: {},
          data: <<~DATA
            IN :country, guard:,          out :PAID, out :PAID_type, out :len
            US,          :CUSIP.present?, :CUSIP,    CUSIP,          :PAID.length
            GB,          :SEDOL.present?, :SEDOL,    SEDOL,          :PAID.length
            ,            :ISIN.present?,  :ISIN,     ISIN,           :PAID.length
            ,            :SEDOL.present?, :SEDOL,    SEDOL,          :PAID.length
            ,            :CUSIP.present?, :CUSIP,    CUSIP,          :PAID.length
            ,            ,                := nil,    MISSING,        := nil
          DATA
        }
      ]
      examples.each do |test|
        %i[decide decide!].each do |method|
          it "#{method} correctly #{test[:example]}" do
            table = CSVDecision.parse(test[:data], test[:options])

            expect(table.send(method, country: 'US',  CUSIP: '123456789'))
              .to eq(PAID: '123456789', PAID_type: 'CUSIP', len: 9)
            expect(table.send(method, country: 'EU',  CUSIP: '123456789', ISIN:'123456789012'))
              .to eq(PAID: '123456789012', PAID_type: 'ISIN', len: 12)
            expect(table.send(method, country: 'AU', ISIN: ''))
              .to eq(PAID: nil, PAID_type: 'MISSING', len: nil)
          end
        end
      end
    end
  end
end