```
# output a list of stripped emails from a CSV
ruby refine.rb a_list_of_emails_and_other_columns.csv --output-columns=email_stripped

# list of emails common to both csvs
ruby refine.rb full_list.csv other_set_to_intersect_with.csv --common --output-columns=email

# merge data from another list & tag
ruby refine.rb import_list.csv external_list_with_zip_and_state_data.csv --merge=zip,State --add-static-column=source,"LIST-TAG-DATA" --open

# tag a list
ruby refine.rb import_list.csv --add-static-column=source,AUG-2013-POSTCARD-IMPORT --output-columns=email_stripped,source --stdout > ~/Desktop/list_import.csv
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
