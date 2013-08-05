# https://github.com/maxogden/refine-python/wiki/Refine-API
# https://github.com/OpenRefine/OpenRefine/blob/a7273625d7c33af70b6d16db5782c802186b3b99/main/webapp/modules/core/MOD-INF/controller.js

require './refine-ruby/lib/google-refine'

csv_a_path = ARGV[0]
csv_b_path = ARGV[1]

# TODO clear out all old CSV a & b or timestamp the new ones

csv_a = Refine.new('csv_a', csv_a_path)
csv_b = Refine.new('csv_b', csv_b_path)

# == normalize the email column

normalize_columns = %q{
[
  {
    "op": "core/column-rename",
    "oldColumnName": "E-mail",
    "newColumnName": "email"
  },
  {
    "op": "core/column-rename",
    "oldColumnName": "Email Address",
    "newColumnName": "email"
  },
  {
    "op": "core/column-rename",
    "oldColumnName": "Email",
    "newColumnName": "email"
  }
]
}

csv_a.apply_operations(normalize_columns)
csv_b.apply_operations(normalize_columns)

email_strip = %q{
[
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "record-based"
    },
    "newColumnName": "email_stripped",
    "columnInsertIndex": 3,
    "baseColumnName": "email",
    "expression": "grel:strip(value.toLowercase())",
    "onError": "set-to-blank"
  }
]
}

# strip & lowercase all emails
csv_a.apply_operations(email_strip)
csv_b.apply_operations(email_strip)

# == create a bool column and export all rows that aren't in the second csv
puts csv_a.apply_operations(%q{
[
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "record-based"
    },
    "newColumnName": "exists",
    "columnInsertIndex": 3,
    "baseColumnName": "email_stripped",
    "expression": "grel:cell.cross(\"csv_b\", \"email_stripped\").cells.length() == 0",
    "onError": "set-to-blank"
  }
]
})

puts csv_a.export_rows(
  "format" => "csv",
  "options" => { "columns" => [{"name" => "email_stripped"}] },
  "facets" => [
    {
      "invert" =>  false,
      "expression" =>  "value",
      "selectError" =>  false,
      "omitError" =>  false,
      "selectBlank" =>  false,
      "name" =>  "exists",
      "omitBlank" =>  false,
      "columnName" =>  "exists",
      "type" =>  "list",
      "selection" =>  [
        {
          "v" =>  {
            "v" =>  true,
            "l" =>  "true"
          }
        }
      ]
    }
  ],
)

csv_b.delete_project

# File.open('merged', 'w') { |f| f.write(csv_a.export_rows('csv')) }
# csv_b.delete_project
