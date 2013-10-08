require "orefine/version"
require 'google-refine'

module Orefine
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
        self.normalize_full_name_column_name(projects)
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

      def normalize_full_name_column_name(projects)
        self.perform_operation(projects, %q{
  [
    {
      "op": "core/column-rename",
      "oldColumnName": "Name",
      "newColumnName": "full_name"
    },
    {
      "op": "core/column-rename",
      "oldColumnName": "Full Name",
      "newColumnName": "full_name"
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
      "columnInsertIndex": 0,
      "baseColumnName": "email",
      "expression": "grel:strip(value.toLowercase())",
      "onError": "set-to-blank"
    }
  ]
        })
      end

      def split_full_name(projects)
        self.perform_operation(projects, %q{
  [
    {
      "op": "core/column-split",
      "description": "Split column Name by separator",
      "engineConfig": {
        "facets": [],
        "mode": "row-based"
      },
      "columnName": "full_name",
      "guessCellType": false,
      "removeOriginalColumn": false,
      "mode": "separator",
      "separator": "(?<=[a-z]) ",
      "regex": true,
      "maxColumns": 2
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
      "columnInsertIndex": 0,
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
end
