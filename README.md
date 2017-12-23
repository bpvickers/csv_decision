CSV Decision
============

[![Gem Version](https://badge.fury.io/rb/csv_decision.svg)](https://badge.fury.io/rb/csv_decision)
[![Build Status](https://travis-ci.org/bpvickers/csv_decision.svg?branch=master)](https://travis-ci.org/bpvickers/csv_decision)
[![Coverage Status](https://coveralls.io/repos/github/bpvickers/csv_decision/badge.svg?branch=master)](https://coveralls.io/github/bpvickers/csv_decision?branch=master)
<a href="https://codeclimate.com/github/bpvickers/csv_decision/maintainability"><img src="https://api.codeclimate.com/v1/badges/466a6c52e8f6a3840967/maintainability" /></a>

### CSV based Ruby decision tables (a lightweight Hash transformation gem)

`csv_decision` is a RubyGem for CSV (comma separated values) based 
[decision tables](https://en.wikipedia.org/wiki/Decision_table). 
It accepts decision tables implemented as a CSV file, which can then be used to 
execute complex conditional logic against an input hash, producing a decision as an 
output hash.

 ### `csv_decision` features
 * Fast decision-time performance (see `benchmark.rb`).
 * In addition to simple string matching, can use regular expressions, 
 numeric comparisons and Ruby-style ranges.
 * Accepts data as a file, CSV string or an array of arrays. (For safety all input data is 
 force encoded to UTF-8, and non-ascii strings are converted to empty strings.)
 * All CSV cells are parsed for correctness, and helpful error messages generated for bad 
 inputs.
 * Either returns the first matching row as a hash, or accumulates all matches as an 
 array of hashes.
 
 ### Planned features
 `csv_decision` is currently a work in progress, and will be enhanced to support
 the following features:
 * Input columns may be indexed for faster lookup performance.
 * May use functions in the output columns to formulate the final decision.
 * Input hash values may be conditionally defaulted using a constant or a function call
 * Use of column symbol references or built-in guard functions in the input
 columns for matching.
 * May be extended with user-defined Ruby functions for tailored logic.
 * Can use post-match guard conditions to filter the results of multi-row 
 decision output.
 
 ### Why use `csv_decision`?
 
 Typical "business logic" is notoriously illogical -- full of corner cases and one-off 
 exceptions. 
 A decision table can capture data-based decisions in a way that comes more naturally 
 to subject matter experts, who typically prefer spreadsheet models. 
 Business logic may then be encapsulated, avoiding the need to write tortuous 
 conditional expressions in Ruby that draw the ire of `rubocop` and its ilk.
 
 This gem takes its inspiration from 
 [rufus/decision](https://github.com/jmettraux/rufus-decision).
 (That gem is no longer maintained and has issues with execution performance.)
 
 ### Installation
 
 To get started, just add `csv_decision` to your `Gemfile`, and then run `bundle`:
 
 ```ruby
 gem 'csv_decision', '~> 0.0.1'
 ```
 
 or simply
 ```bash
 gem install csv_decision
 ```
 
 ### Simple example
 
 A decision table may be as simple or as complex as you like (although very complex 
 tables defeat the whole purpose). 
 Basic usage will be illustrated by an example taken from:
 https://jmettraux.wordpress.com/2009/04/25/rufus-decision-11-ruby-decision-tables/.
 
 This example considers two input conditions: `topic` and `region`.
 These are labeled `in`. Certain combinations yield an output value for `team_member`, 
 labeled `out`.
 
```
in :topic | in :region  | out :team_member
----------+-------------+-----------------
sports    | Europe      | Alice
sports    |             | Bob
finance   | America     | Charlie
finance   | Europe      | Donald
finance   |             | Ernest
politics  | Asia        | Fujio
politics  | America     | Gilbert
politics  |             | Henry
          |             | Zach
```
 
 When the topic is `finance` and the region is `Europe` the team member `Donald`
 is selected.
 
 This is a "first match" decision table in that as soon as a match is made execution
 stops and a single output value (hash) is returned. 
 
 The ordering of rows matters. `Ernest`, who is in charge of `finance` for the rest of 
 the world, except for `America` and `Europe`, *must* come after his colleagues 
 `Charlie` and `Donald`. `Zach` has been placed last, catching all the input combos
 not matching any other row.
 
 Now for some code.
 
 ```ruby
  # Valid CSV string
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

  table = CSVDecision.parse(data)
  
  table.decide(topic: 'finance', region: 'Europe') # returns team_member: 'Donald'
  table.decide(topic: 'sports', region: nil) # returns team_member: 'Bob'
  table.decide(topic: 'culture', region: 'America') # team_member: 'Zach'
```
 
 An empty `in` cell means "matches any value".
 
 If you have cloned this gem's git repo, then this example can also be run by loading
 the table from a CSV file:
 
 ```ruby
table = CSVDecision.parse(Pathname('spec/data/valid/simple_example.csv'))
```
 
 We can also load this same table using the option: `first_match: false`.
 
 ```ruby
table = CSVDecision.parse(data, first_match: false)
table.decide(topic: 'finance', region: 'Europe') # returns team_member: %w[Donald Ernest Zach] 
```


 For more examples see `spec/csv_decision/table_spec.rb`. 
 Complete documentation of all table parameters is in the code - see 
 `lib/csv_decision/parse.rb` and `lib/csv_decision/table.rb`.
 
 
 ### Testing
 
 `csv_decision` includes thorough [RSpec](http://rspec.info) tests:
 
 ```bash
 # Execute within a clone of the csv_decision Git repository:
 bundle install
 rspec
 ```
