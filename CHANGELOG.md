## v0.5.0, 11 February 2018.
*Additions*
- Add the ability to specify an input hash path using path: column types.

## v0.4.1, 10 February 2018.
*Additions*
- For consistency, input columns may now use the form `!nil?` to negate 0-arity Ruby methods.
(Typical SME users can be somewhat lax with syntax.)

## v0.4.0, 28 January 2018.
*Additions*
- Input columns may now use 0-arity Ruby methods to implement conditional logic.
For example `.present?` or `nil?`. Negation is also supported - e.g., `!.nil?`.

## v0.3.2, 28 January 2018.
*Changes*
- Refactor code and update documentation.

## v0.3.1, 21 January 2018.
*Changes*
- Optimize code.

## v0.3.0, 20 January 2018.
*Additions*
- Index one or more text-only input columns for faster lookup performance.

## v0.2.0, 13 January 2018.
*Additions*
- Set values in the input hash either as a default or unconditionally.

## v0.1.0, 5 January 2018.
*Additions*
- Implement more checks on output columns that are duplicated or
reference columns that appear after them.

## v0.0.9, 5 January 2018.
*Additions*
- Output column if: filter conditions.

## v0.0.8, 31 December 2017.
*Additions*
- Guard conditions can use `=~` and `!~` for regular expressions.

*Fixes*
- Bug with column symbol expression not recognising >= and <=.

## v0.0.7, 30 December 2017.
*Additions*
- Guard conditions using column symbols and expressions.
- Guard columns.
- Symbol functions (0-arity) in output columns.
- Update YARD documentation.

## v0.0.6, 26 December 2017.
*Additions*
- Update YARD documentation.

## v0.0.5, 26 December 2017.
*Additions*
- Update YARD documentation.

## v0.0.4, 26 December 2017.
*Additions*
- Adds symbol expressions for input columns.
- Adds non-string constants for output columns.
- Support Ruby 2.5.0
- Include YARD documentation.

*Changes*
- Move `benchmark.rb` to `benchmarks` folder and rename to `rufus_decision.rb`

## v0.0.3, 18 December 2017.
*Additions*
- Add non-string constants for input columns.

## v0.0.2, 18 December 2017.
*Additions*
- Adds accumulate option.

## v0.0.1, 18 December 2017.
- Initial release
