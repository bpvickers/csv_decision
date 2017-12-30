CSV Decision
============

[![Gem Version](https://badge.fury.io/rb/csv_decision.svg)](https://badge.fury.io/rb/csv_decision)
[![Build Status](https://travis-ci.org/bpvickers/csv_decision.svg?branch=master)](https://travis-ci.org/bpvickers/csv_decision)
[![Coverage Status](https://coveralls.io/repos/github/bpvickers/csv_decision/badge.svg?branch=master)](https://coveralls.io/github/bpvickers/csv_decision?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/466a6c52e8f6a3840967/maintainability)](https://codeclimate.com/github/bpvickers/csv_decision/maintainability)
[![License](http://img.shields.io/badge/license-MIT-yellowgreen.svg)](#license)

### CSV based Ruby decision tables

`csv_decision` is a RubyGem for CSV (comma separated values) based 
[decision tables](https://en.wikipedia.org/wiki/Decision_table). 
It accepts decision tables implemented as a 
[CSV file](https://en.wikipedia.org/wiki/Comma-separated_values), 
which can then be used to execute complex conditional logic against an input hash, 
producing a decision as an output hash.

### Why use `csv_decision`?
 
Typical "business logic" is notoriously illogical -- full of corner cases and one-off 
exceptions. 
A decision table can express data-based decisions in a way that comes more naturally 
to subject matter experts, who typically prefer spreadsheet models. 
Business logic may then be encapsulated, avoiding the need to write tortuous 
conditional expressions in Ruby that draw the ire of `rubocop` and its ilk.

This gem and the examples below take inspiration from 
[rufus/decision](https://github.com/jmettraux/rufus-decision).
(That gem is no longer maintained and CSV Decision has better 
decision-time performance, at the expense of slower table parse times and more memory -- 
see `benchmarks/rufus_decision.rb`.)
 
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
  
This table considers two input conditions: `topic` and `region`.
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
stops and a single output row (hash) is returned. 

The ordering of rows matters. `Ernest`, who is in charge of `finance` for the rest of 
the world, except for `America` and `Europe`, *must* come after his colleagues 
`Charlie` and `Donald`. `Zach` has been placed last, catching all the input combos
not matching any other row.

Here is the example as code:
 
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
  
  table.decide(topic: 'finance', region: 'Europe') #=> { team_member: 'Donald' }
  table.decide(topic: 'sports', region: nil) #=> { team_member: 'Bob' }
  table.decide(topic: 'culture', region: 'America') #=> { team_member: 'Zach' }
```
 
An empty `in` cell means "matches any value", even nils.

If you have cloned this gem's git repo, then the example can also be run by loading
the table from a CSV file:
 
 ```ruby
table = CSVDecision.parse(Pathname('spec/data/valid/simple_example.csv'))
```
 
We can also load this same table using the option: `first_match: false`, which means that 
*all* matching rows will be accumulated into an array of hashes.
 
 ```ruby
table = CSVDecision.parse(data, first_match: false)
table.decide(topic: 'finance', region: 'Europe') #=> { team_member: %w[Donald Ernest Zach] }
```

For more examples see `spec/csv_decision/table_spec.rb`. 
Complete documentation of all table parameters is in the code - see 
`lib/csv_decision/parse.rb` and `lib/csv_decision/table.rb`.

### CSV Decision features
 * Either returns the first matching row as a hash (default), or accumulates all matches as an 
 array of hashes (i.e., `parse` option `first_match: false` or CSV file option `accumulate`.)
 * Fast decision-time performance (see `benchmarks` folder).
 * In addition to simple strings, `csv_decision` can match basic Ruby constants (e.g, `=nil`), 
 regular expressions (e.g., `=~ on|off`), comparisons (e.g., `> 100.0` ) and 
 Ruby-style ranges (e.g, `1..10`)
 * Can compare an input column versus another input hash key -- e.g., `> :column`.
 * Any cell starting with `#` is treated as a comment, and comments may appear anywhere in the
 table. (Comment cells are always interpreted as the empty string.)
 * Can use column symbol expressions or Ruby methods (0-arity) in input columns for 
 matching - e.g, `:column.zero?` or `:column == 0`.
 * May also use Ruby methods in output columns - e.g., `:column.length`.
 * Accepts data as a file, CSV string or an array of arrays. (For safety all input data is 
 force encoded to UTF-8, and non-ascii strings are converted to empty strings.)
 * All CSV cells are parsed for correctness, and helpful error messages generated for bad 
 input.
  
### Constants other than strings
Although `csv_decision` is string oriented, it does recognise other types of constant
present in the input hash. Specifically, the following classes are recognized: 
`Integer`, `BigDecimal`, `NilClass`, `TrueClass` and `FalseClass`. 

This is accomplished by prefixing the value with one of the operators `=`, `==` or `:=`. 
(The syntax is intentionally lax.)

For example:
 ```ruby
    data = <<~DATA
      in :constant, out :value
      :=nil,        :=nil
      ==false,      ==false
      =true,        =true
      = 0,          = 0
      :=100.0,      :=100.0
    DATA
          
  table = CSVDecision.parse(data)
  table.decide(constant: nil) # returns value: nil      
  table.decide(constant: 0) # returns value: 0        
  table.decide(constant: BigDecimal('100.0')) # returns value: BigDecimal('100.0')       
```
 
### Column header symbols
All input and output column names are symbolized, and can be used to form simple
expressions that refer to values in the input hash.

For example:
 ```ruby
    data = <<~DATA
      in :node, in :parent, out :top?
      ,         == :node,   yes
      ,         ,           no
    DATA
    
    table = CSVDecision.parse(data)
    table.decide(node: 0, parent: 0) # returns top?: 'yes'
    table.decide(node: 1, parent: 0) # returns top?: 'no'
 ```
 
Note that there is no need to include an input column for `:node` in the decision 
table - it just needs to be present in the input hash. Also, `== :node` can be 
shortened to just `:node`, so the above decision table may be simplified to:

 ```ruby
    data = <<~DATA
      in :parent, out :top?
         :node,   yes
      ,           no
    DATA
 ```
These comparison operators are also supported: `!=`, `>`, `>=`, `<`, `<=`.
For more simple examples see `spec/csv_decision/examples_spec.rb`.

### Column guard conditions
Sometimes it's more convenient to write guard conditions in a single column specialized for that purpose. 
For example:

```ruby
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
table.decide(country: 'US',  CUSIP: '123456789') #=> { ID: '123456789', ID_type: 'CUSIP', len: 9 }
table.decide(country: 'EU',  CUSIP: '123456789', ISIN:'123456789012') 
  #=> { ID: '123456789012', ID_type: 'ISIN', len: 12 }
```
Guard columns may be anonymous, and must contain non-constant expressions. In addition to
0-arity Ruby methods, the following comparison operators are also supported: `==`, `!=`,
`>`, `>=`, `<` and `<=`.
  
### Testing
 
 `csv_decision` includes thorough [RSpec](http://rspec.info) tests:
 
 ```bash
 # Execute within a clone of the csv_decision Git repository:
 bundle install
 rspec
 ```

### Planned features
 `csv_decision` is still a work in progress, and will be enhanced to support
 the following features:
 * Text-only input columns may be indexed for faster lookup performance.
 * Supply a pre-defined library of functions that can be called within input columns to 
   implement matching logic or from the output columns to formulate the final decision.
 * Available functions may be extended with a user-supplied library of Ruby methods 
   for tailored logic.
 * Input hash values may be (conditionally) defaulted with a constant or a function call.
 * Output columns may construct interpolated strings referencing column symbols.
 * Can use post-match guard conditions to filter the results of multi-row 
   decision output.
 
### Reasons for the limitations of column expressions
The simple column expressions allowed by `csv_decision` are purposely limited for reasons of
understandability and maintainability. The whole point of this gem is to make decision rules
easier to express and comprehend as declarative, tabular logic.
While Ruby makes it easy to execute arbitrary code embedded within a CSV file, 
this could easily result in hard to debug logic that also poses safety risks.