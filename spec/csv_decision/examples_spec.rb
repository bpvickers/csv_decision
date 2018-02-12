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
      in :constant, out :value
      :=nil,        :=nil
      ==false,      ==false
      =true,        =true
      = 0,          = 0
      :=100.0,      :=100.0
    DATA

    it 'makes correct decisions for CSV string' do
      table = CSVDecision.parse(data)

      result = table.decide(constant: nil)
      expect(result).to eq(value: nil)

      result = table.decide(constant: true)
      expect(result).to eq(value: true)

      result = table.decide(constant: false)
      expect(result).to eq(value: false)

      result = table.decide(constant: 0)
      expect(result).to eq(value: 0)

      result = table.decide(constant: BigDecimal('100.0'))
      expect(result).to eq(value: BigDecimal('100.0'))
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

  context 'simple example - column symbols not in header' do
    data = <<~DATA
      in :parent, out :top?
      ==:node,   yes
      ,          no
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

  it 'makes correct decision for table with symbol ordered compares' do
    data = <<~DATA
      in :traded, in :settled, out :status
      ,            :traded,    same day
      ,           >:traded,    pending
      ,           <:traded,    invalid trade
      ,                   ,    invalid data
    DATA
    table = CSVDecision.parse(data)

    expect(table.columns.input_keys).to eq %i[traded settled]

    expect(table.decide(traded: '20171227',  settled: '20171227')).to eq(status: 'same day')
    expect(table.decide(traded:  20171227,   settled:  20171227 )).to eq(status: 'same day')
    expect(table.decide(traded: '20171227',  settled: '20171228')).to eq(status: 'pending')
    expect(table.decide(traded:  20171227,   settled:  20171228 )).to eq(status: 'pending')
    expect(table.decide(traded: '20171228',  settled: '20171227')).to eq(status: 'invalid trade')
    expect(table.decide(traded:  20171228,   settled:  20171227 )).to eq(status: 'invalid trade')
    expect(table.decide(traded: '20171227',  settled:  20171228 )).to eq(status: 'invalid data')
  end
  
  it 'makes a correct decision using a guard column' do
    data = <<~DATA
      in :country, guard:,          out :ID, out :ID_type, out :len
      US,          :CUSIP.present?, :CUSIP,  CUSIP,        :ID.length
      GB,          :SEDOL.present?, :SEDOL,  SEDOL,        :ID.length
      ,            :ISIN.present?,  :ISIN,   ISIN,         :ID.length
      ,            :SEDOL.present?, :SEDOL,  SEDOL,        :ID.length
      ,            :CUSIP.present?, :CUSIP,  CUSIP,        :ID.length
      ,            ,                := nil,  := nil,       := nil
    DATA

    table = CSVDecision.parse(data)

    expect(table.decide(country: 'US',  CUSIP: '123456789'))
      .to eq(ID: '123456789', ID_type: 'CUSIP', len: 9)
    expect(table.decide(country: 'EU',  CUSIP: '123456789', ISIN:'123456789012'))
      .to eq(ID: '123456789012', ID_type: 'ISIN', len: 12)
  end

  it 'makes a correct decision using an if column' do
    data = <<~DATA
      in :country, guard:,          out :ID, out :ID_type, out :len,  if:
      US,          :CUSIP.present?, :CUSIP,  CUSIP8,       :ID.length, :len == 8
      US,          :CUSIP.present?, :CUSIP,  CUSIP9,       :ID.length, :len == 9
      US,          :CUSIP.present?, :CUSIP,  DUMMY,        :ID.length,
      ,            :ISIN.present?,  :ISIN,   ISIN,         :ID.length, :len == 12
      ,            :ISIN.present?,  :ISIN,   DUMMY,        :ID.length,
      ,            :CUSIP.present?, :CUSIP,  DUMMY,        :ID.length,
      DATA

    table = CSVDecision.parse(data)

    expect(table.decide(country: 'US',  CUSIP: '12345678'))
      .to eq(ID: '12345678', ID_type: 'CUSIP8', len: 8)
    expect(table.decide(country: 'US',  CUSIP: '123456789'))
      .to eq(ID: '123456789', ID_type: 'CUSIP9', len: 9)
    expect(table.decide(country: 'US',  CUSIP: '1234567890'))
      .to eq(ID: '1234567890', ID_type: 'DUMMY', len: 10)
    expect(table.decide(country: nil,  CUSIP: '123456789', ISIN:'123456789012'))
      .to eq(ID: '123456789012', ID_type: 'ISIN', len: 12)
    expect(table.decide(CUSIP: '12345678', ISIN:'1234567890'))
      .to eq(ID: '1234567890', ID_type: 'DUMMY', len: 10)
  end

  it 'recognises the set: columns and uses correct defaults' do
    data = <<~DATA
      set/nil? :country, guard:,          set: class,    out :PAID, out: len,     if:
      US,                ,                :class.upcase,
      US,                :CUSIP.present?, != PRIVATE,    :CUSIP,    :PAID.length, :len == 9
      !=US,              :ISIN.present?,  != PRIVATE,    :ISIN,     :PAID.length, :len == 12
      US,                :CUSIP.present?, PRIVATE,       :CUSIP,    :PAID.length,
      !=US,              :ISIN.present?,  PRIVATE,       :ISIN,     :PAID.length,
    DATA

    table = CSVDecision.parse(data)
    expect(table.decide(CUSIP: '1234567890', class: 'Private')).to eq(PAID: '1234567890', len: 10)
    expect(table.decide(CUSIP: '123456789', class: 'Public')).to eq(PAID: '123456789', len: 9)
    expect(table.decide(ISIN: '123456789', country: 'GB', class: 'public')).to eq({})
    expect(table.decide(ISIN: '123456789012', country: 'GB', class: 'private')).to eq(PAID: '123456789012', len: 12)
  end

  it 'recognises in column method call conditions' do
    data = <<~DATA
      set/nil? :country, in :CUSIP,       in :ISIN,   set: class,    out :PAID, out: len,     if:
      US,                ,                ,           :class.upcase,
      US,                .present?,       ,           != PRIVATE,    :CUSIP,    :PAID.length, :len == 9
      !=US,              ,                .present?,  != PRIVATE,    :ISIN,     :PAID.length, :len == 12
      US,                =.present?,      ,           PRIVATE,       :CUSIP,    :PAID.length,
      !=US,              ,                !.blank?,   PRIVATE,       :ISIN,     :PAID.length,
    DATA

    table = CSVDecision.parse(data)
    expect(table.decide(CUSIP: '1234567890', class: 'Private')).to eq(PAID: '1234567890', len: 10)
    expect(table.decide(CUSIP: '123456789', class: 'Public')).to eq(PAID: '123456789', len: 9)
    expect(table.decide(ISIN: '123456789', country: 'GB', class: 'public')).to eq({})
    expect(table.decide(ISIN: '123456789012', country: 'GB', class: 'private')).to eq(PAID: '123456789012', len: 12)
  end

  it 'scans the input hash paths accumulating matches' do
    data = <<~DATA
      path:,   path:,    out :value
      header,  ,         :source_name
      header,  metrics,  :service_name
      payload, ,         :amount
      payload, ref_data, :account_id
    DATA
    table = CSVDecision.parse(data, first_match: false)

    input = {
      header: {
        id: 1, type_cd: 'BUY', source_name: 'Client', client_name: 'AAPL',
        metrics: { service_name: 'Trading', receive_time: '12:00' }
      },
      payload: {
        tran_id: 9, amount: '100.00',
        ref_data: { account_id: '5010', type_id: 'BUYL' }
      }
    }

    expect(table.decide(input)).to eq(value: %w[Client Trading 100.00 5010])
    expect(table.decide!(input)).to eq(value: %w[Client Trading 100.00 5010])
  end
end