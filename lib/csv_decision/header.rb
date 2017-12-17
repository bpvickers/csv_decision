# frozen_string_literal: true

# CSV Decision: CSV based Ruby decision tables.
# Created December 2017 by Brett Vickers
# See LICENSE and README.md for details.
module CSVDecision
  # Parse the CSV file's header row
  class Header
    # Column header looks like IN :col_name or if:
    COLUMN_TYPE = %r{\A(in|out|in/text|out/text)|set\s*:\s*(\S?.*)\z}i

    def self.row?(row)
      row.find { |cell| cell.match(COLUMN_TYPE) }
    end

    # Parse the input data which may either be a path name, CSV string or array of arrays
    def self.parse(table:, options: {})
      header = Header.new

      header.freeze
    end
  end
end