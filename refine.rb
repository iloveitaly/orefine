# https://github.com/maxogden/refine-python/wiki/Refine-API
# https://github.com/OpenRefine/OpenRefine/blob/a7273625d7c33af70b6d16db5782c802186b3b99/main/webapp/modules/core/MOD-INF/controller.js
# http://blog.ouseful.info/2011/05/06/merging-datesets-with-common-columns-in-google-refine/
# https://github.com/OpenRefine/OpenRefine/wiki/GREL-Other-Functions

require './refine-ruby/lib/google-refine'
require 'slop'

class CSVUtil
  class << self
    def clear_all_csvs
      Refine.get_all_project_metadata["projects"]
            .select { |k, v| v["name"].start_with?('csv_') }
            .keys
            .map { |project_id| Refine.new("project_id" => project_id) }
            .map(&:delete_project)
    end

    def normalize_column_names(projects)
      self.normalize_email_column_name(projects)
      self.normalize_zip_column_name(projects)
    end

    def normalize_email_column_name(projects)
      self.perform_operation(projects, %q{
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
  },
  {
    "op": "core/column-rename",
    "oldColumnName": "[email]",
    "newColumnName": "email"
  },
  {
    "op": "core/column-rename",
    "oldColumnName": "email_stripped",
    "newColumnName": "email"
  },  
]
      })
    end

    def normalize_zip_column_name(projects)
      self.perform_operation(projects, %q{
[
  {
    "op": "core/column-rename",
    "oldColumnName": "Zip",
    "newColumnName": "zip"
  },
  {
    "op": "core/column-rename",
    "oldColumnName": "[zip]",
    "newColumnName": "zip"
  }
]
      })
    end

    def normalize_email_column_content(projects)
      self.perform_operation(projects, %q{
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
      })
    end

    def create_common_flag(project_a, project_b)
      if project_a.get_columns_info.map { |c| c["name"] }.include? 'exists'
        STDERR.puts "'exists' column already exists in csv_a, deleting"
        self.delete_column(project_a, "exists")
      end

      self.perform_operation(project_a, %Q{
[
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "record-based"
    },
    "newColumnName": "exists",
    "columnInsertIndex": 0,
    "baseColumnName": "email_stripped",
    "expression": "grel:cell.cross(\\\"#{project_b.project_name}\\\", \\\"email_stripped\\\").cells.length() > 0",
    "onError": "set-to-blank"
  }
]
      })
    end

    def merge_field(project_a, project_b, field)
      self.perform_operation(project_a, %Q{
[
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "record-based"
    },
    "newColumnName": "#{field}_merged",
    "columnInsertIndex": 3,
    "baseColumnName": "email_stripped",
    "expression": "grel:cell.cross(\\\"#{project_b.project_name}\\\", \\\"email_stripped\\\").cells[\\\"#{field}\\\"].value[0]",
    "onError": "set-to-blank"
  }
]
      })
    end

    def merge_common_field(csv_a, csv_b, common_field)
      
    end

    def delete_column(csv, field)
      self.perform_operation(csv, %Q{
[
  {
    "op": "core/column-removal",
    "columnName": "#{field}"
  }
]
      })
    end

    def add_column(csv, field, value)
      self.perform_operation(csv, %Q{
[
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "record-based"
    },
    "newColumnName": "#{field}",
    "columnInsertIndex": 0,
    "baseColumnName": "email_stripped",
    "expression": "grel:\\\"#{value}\\\"",
    "onError": "set-to-blank"
  }
]
      })
    end

    def common_facet(flag = true)
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
              # string vs boolean matters here... be careful
              "v" =>  flag,
              "l" =>  flag,
            }
          }
        ]
      }
    end

    def perform_operation(projects, operation)
      projects = [projects] if !projects.is_a?(Array)
      projects.each { |p| p.apply_operations(operation) }
    end
  end
end

$opts = Slop.parse do
  banner 'Usage: refine.rb csv_a csv_b [options]'

  on 'output-columns=', 'Your name', as: Array
  on 'delete-columns=', 'What columns to delete from the output', as: Array
  on 'merge=', 'What column to merge in from csv_b', as: Array
  on 'add-static-column=', 'Add a column with a static value (input: key, value)', as: Array
  on 'merge-common=', 'Merge values from common columns with a comma'

  on 'diff', 'only output rows in csv_a whose email does not exist in csv_b'
  on 'common', 'only output rows common to both csvs'

  on 'open', 'open the document in a web browser'
  on 'stdout', 'write the resulting csv to stdout'
end

csv_a_path = ARGV[0]
csv_b_path = ARGV[1]

# TODO clear out all old CSV a & b or timestamp the new ones

CSVUtil.clear_all_csvs
csv_a = Refine.new("project_name" => 'csv_a', "file_name" => csv_a_path)
csv_b = Refine.new("project_name" => 'csv_b', "file_name" => csv_b_path) if !csv_b_path.empty? && File.exists?(csv_b_path)

all_csvs = [csv_a]
all_csvs << csv_b if !csv_b.nil?

CSVUtil.normalize_column_names(all_csvs)
CSVUtil.normalize_email_column_content(all_csvs)
CSVUtil.create_common_flag(csv_a, csv_b) if !csv_b.nil?

if !$opts['merge'].nil?
  $opts['merge'].each do |merge_field|
    CSVUtil.merge_field(csv_a, csv_b, merge_field)
  end
end

if !$opts['merge-common'].nil?
  $opts['merge-common'].each do |common_merge|
    CSVUtil.merge_common_field(csv_a, csv_b, common_merge)
  end
end

if !$opts['add-static-column'].nil?
  puts $opts['add-static-column']
  CSVUtil.add_column(csv_a, $opts['add-static-column'].first, $opts['add-static-column'].last)
end

output_params = { "format" => "csv" }

if !$opts['output-columns'].nil?
  output_params["options"] ||= {}
  output_params["options"]["columns"] ||= []

  $opts['output-columns'].each do |c|
    output_params["options"]["columns"] << { "name" => c }
  end
end

if !$opts['delete-columns'].nil?
  $opts['delete-columns'].each do |column_name|
    CSVUtil.delete_column(csv_a, column_name)
  end
end

if !csv_b.nil? && ($opts.diff? || $opts.common?)
  flag = true
  flag = false if $opts.diff?

  output_params["facets"] = [ CSVUtil.common_facet(flag) ]
end

puts csv_a.export_rows(output_params) if $opts.stdout?

`open "http://127.0.0.1:3333/project?project=#{csv_a.project_id}"` if $opts.open?
