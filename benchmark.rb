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
    data: 'simple_example.csv',
    input: { 'topic' => 'culture', 'region' => 'America' },
    # Expected results for first_match and accumulate
    first_match: { 'team_member' => 'Zach' }
  }
].deep_freeze

tag_width = 70

puts ""
puts "Benchmarking Memory"
puts '=' * tag_width
puts ""

def benchmark_memory(test, quiet: false)
  name = test[:name]
  data = Pathname(File.join(SPEC_DATA_VALID, test[:data]))
  file_name = data.to_s

  rufus_tables = {}
  csv_tables = {}
  key = File.basename(file_name, '.csv').to_sym

  Benchmark.memory(quiet: quiet) do |x|
    GC.start
    x.report("Rufus new table - #{name}        ") do
      rufus_tables[key] = Rufus::Decision::Table.new(file_name, RUFUS_OPTIONS)
    end

    GC.start
    x.report("CSV Decision new table - #{name} ") do
      csv_tables[key] = CSVDecision.parse(data, CSV_OPTIONS)
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
  data = Pathname(File.join(SPEC_DATA_VALID, test[:data]))
  file_name = data.to_s

  Benchmark.ips do |x|
    GC.start
    x.report("CSV new table   - #{name}: ") do |count|
      count.times { CSVDecision.parse(data) }
    end

    GC.start
    x.report("Rufus new table - #{name}: ") do |count|
      count.times { Rufus::Decision::Table.new(file_name, RUFUS_OPTIONS) }
    end

    x.compare!
  end
end

puts ""
puts "Benchmarking Decisions per Second"
puts '=' * tag_width
puts ""

# First match true and false run options
[true].each do |first_match|
  puts "Table Decision Option: first_match: #{first_match}"
  puts '-' * tag_width

  csv_options = CSV_OPTIONS.merge(first_match: first_match)
  rufus_options = RUFUS_OPTIONS.merge(first_match: first_match)

  benchmarks.each do |test|
    name = test[:name]
    data = Pathname(File.join(SPEC_DATA_VALID, test[:data]))

    rufus_table = Rufus::Decision::Table.new(data.to_s, rufus_options)
    csv_table = CSVDecision.parse(data, csv_options)

    # Prepare input hash
    input = test[:input].deep_dup
    input_symbolized = input.symbolize_keys

    # Test expected results
    expected = first_match ? test[:first_match] : test[:accumulate]

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
      x.report("CSV decision   (first_match: #{first_match}) - #{name}: ") do |count|
        count.times { csv_table.decide!(input_symbolized) }
      end

      GC.start
      x.report("Rufus decision (first_match: #{first_match}) - #{name}: ") do |count|
        count.times { rufus_table.transform!(input) }
      end

      x.compare!
    end
  end
end


