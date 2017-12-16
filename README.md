# csv-decision - Work In Progress
`csv-decision` is a Ruby gem for CSV based decision tables. It accepts decision table logic encoded in
a CSV file, which can then be used to implement complex conditional logic.

`csv-decision` has many useful features:
 * able to parse and load into memory many CSV files for subsequent processing
 * can return the first matching row as a hash, or accumulate all matches as an array of hashes
 * input columns may be indexed for fast lookup performance
 * can use regular expressions, Ruby-style ranges and function calls to implement complex decision logic
 * all CSV cells are parsed for correctness, and friendly error messages generated for bad input
 * can be safely extended with user defined Ruby functions for tailored logic
 * good decision time performance
 * flexible options for tailoring behavior and defaults
 
 ### Why use CSV Decision?
 
 Typical "business logic" is notoriously illogical -- full of corner cases and irregular exceptions. 
 A decision table can capture data-based decisions in a way that comes naturally to analysts and subject matter 
 experts, who typically use spreadsheet models. Business logic can be encapsulated, avoiding the need to write
 tortuous conditional expressions in Ruby that draws the ire of `rubocop` and its ilk.
