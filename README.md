csv_decision (Work In Progress)
===============================

# CSV based Ruby decision tables

`csv_decision` is a Ruby gem for CSV (comma separated values) based decision tables. 
It accepts decision table logic encoded in a CSV file, which can then be used to implement 
complex conditional logic. Alternatively, `csv_decision` will accept data as a CSV string
or an array of arrays.

`csv_decision` has many useful features:
 * able to parse and load into memory one or more CSV files for subsequent 
 processing
 * all CSV cells are parsed for correctness, and helpful error messages generated for bad inputs
 * either returns the first matching row as a hash, or accumulates all matches as an array of 
 hashes (planed feature)
 * can use regular expressions, Ruby-style ranges and column symbol expressions (planed feature)
 * excellent decision-time performance
 * can be safely extended with user-defined Ruby functions for tailored logic (planed feature)
 to implement complex matching logic
 * input columns may be indexed for fast lookup performance (planed feature)
 
 ### Why use CSV Decision?
 
 Typical "business logic" is notoriously illogical -- full of corner cases, irregularities
 and one-off exceptions. 
 A decision table can capture data-based decisions in a way that comes naturally to analysts 
 and subject matter experts, who typically use spreadsheet models. Business logic can then be 
 encapsulated, avoiding the need to write tortuous conditional expressions in Ruby that draws 
 the ire of `rubocop` and its ilk.
 
 This gem takes its inspiration from [rufus/decision](https://github.com/jmettraux/rufus-decision),
 but that gem is no longer maintained and has issues with execution performance.
 
 ### Simple Example
 
 A decision table can be as simple or as complex as you like (although overly complex tables 
 defeat the whole pupose).
 
 Basic usuage will be illustrated by an example taken from 
 https://jmettraux.wordpress.com/2009/04/25/rufus-decision-11-ruby-decision-tables/.
 
 
 
