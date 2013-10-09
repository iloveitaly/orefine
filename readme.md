# ORefine - CLI for Working With Open Refine
Makes working with CSVs a bit less painful. Tries to automate some common operations. Contributions welcome, this is a rough cut with the minimal features I needed to get a job done.

You'll need [OpenRefine](https://github.com/OpenRefine/OpenRefine) installed & running.

## Examples
```
# output a list of stripped emails from a CSV
orefine a_list_of_emails_and_other_columns.csv --output-columns=email_stripped --stdout

# list of emails common to both csvs
orefine full_list.csv other_set_to_intersect_with.csv --common --output-columns=email --stdout

# merge data from another list & tag
orefine import_list.csv external_list_with_zip_and_state_data.csv --merge=zip,State --add-static-column=source,"LIST-TAG-DATA" --open

# tag a list
orefine import_list.csv --add-static-column=source,AUG-2013-POSTCARD-IMPORT --output-columns=email_stripped,source --stdout > ~/Desktop/list_import.csv
```

## Development Resources
* [OpenRefine API](https://github.com/OpenRefine/OpenRefine/blob/a7273625d7c33af70b6d16db5782c802186b3b99/main/webapp/modules/core/MOD-INF/controller.js)
* [GRel cross documentation](https://github.com/OpenRefine/OpenRefine/wiki/GREL-Other-Functions)
* [Google Refine Gem](https://github.com/iloveitaly/refine-ruby)
* [Tutorial on merging datasets with a common column](http://blog.ouseful.info/2011/05/06/merging-datesets-with-common-columns-in-google-refine/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Authors
* Mike Bianco, @iloveitaly
