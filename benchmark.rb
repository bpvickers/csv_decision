# frozen_string_literal: true

require 'benchmark/ips'
require 'benchmark/memory'
require 'rufus/decision'
require 'ice_nine'
require 'ice_nine/core_ext/object'

require_relative 'lib/csv_decision'

SPEC_DATA_VALID ||= File.join(CSVDecision.root, 'spec', 'data', 'valid')

CSV_OPTIONS = { regexp_implicit: true }
RUFUS_OPTIONS = { open_uri: false, ruby_eval: false }

benchmarks = [
  {
    name: 'String compares only (no index)',
    data: Pathname(File.join(SPEC_DATA_VALID, 'simple_example.csv')),
    input: { 'topic' => 'culture', 'region' => 'America' },
    expected: { 'team_member' => 'Zach' }
  }
].deep_freeze

tag_width = 70

puts ""
puts "Benchmarking Memory"
puts '=' * tag_width
puts ""

def benchmark_memory(test, quiet: false)
  rufus_tables = {}
  csv_tables = {}

  name = test[:name]
  data = test[:data]
  rufus_data = data.to_s

  Benchmark.memory(quiet: quiet) do |x|
    GC.start
    x.report("Rufus new table - #{name}        ") do
      rufus_tables[name] = Rufus::Decision::Table.new(rufus_data, RUFUS_OPTIONS)
    end

    GC.start
    x.report("CSV Decision new table - #{name} ") do
      csv_tables[name] = CSVDecision.parse(data, CSV_OPTIONS)
    end

    x.compare!
  end
end

# Warmup
benchmarks.each { |test| benchmark_memory(test, quiet: true) }

# Run the test
benchmarks.each { |test| benchmark_memory(test, quiet: false) }

puts ""
puts "Benchmarking Table Loads per Second"
puts '=' * tag_width
puts ""

benchmarks.each do |test|
  name = test[:name]
  data = test[:data]
  rufus_data = data.to_s

  Benchmark.ips do |x|
    GC.start
    x.report("CSV new table   - #{name}: ") do |count|
      count.times { CSVDecision.parse(data) }
    end

    GC.start
    x.report("Rufus new table - #{name}: ") do |count|
      count.times { Rufus::Decision::Table.new(rufus_data, RUFUS_OPTIONS) }
    end

    x.compare!
  end
end

puts ""
puts "Benchmarking Decisions per second"
puts '=' * tag_width
puts ""

%i[first_match].each do |option|
  puts "Table Decision Option: #{option}"
  puts '-' * tag_width

  csv_options = CSV_OPTIONS.merge(option => true)
  rufus_options = RUFUS_OPTIONS.merge(option => true)

  benchmarks.each do |test|
    name = test[:name]
    data = test[:data]
    rufus_table = Rufus::Decision::Table.new(data.to_s, rufus_options)
    csv_table = CSVDecision.parse(data, csv_options)

    # Prepare input hash
    input = test[:input].deep_dup
    input_symbolized = input.deep_symbolize_keys

    # Test expected results
    expected = test[:expected]
    result = rufus_table.transform!(input)
    unless result.slice(*expected.keys).eql?(expected)
      raise "Rufus expected results check failed for test: #{name}"
    end

    result = csv_table.decide!(input_symbolized)
    unless result.eql?(expected.symbolize_keys)
      raise "CSV Decision expected results check failed for test: #{name}"
    end

    Benchmark.ips do |x|
      GC.start
      x.report("CSV Decision (#{option}) - #{name}: ") do |count|
        count.times { csv_table.decide!(input_symbolized) }
      end

      GC.start
      x.report("Rufus        (#{option}) - #{name}: ") do |count|
        count.times { rufus_table.transform!(input) }
      end

      x.compare!
    end
  end
end


