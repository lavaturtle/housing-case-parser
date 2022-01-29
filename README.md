WebCivil Local does not allow direct bot access, so we need to do the following to use this tool:

1. Perform a query and request the result as HTML
2. Save the page as a .html file (e.g. listing.html)
3. Run `bundle exec ./parse.rb listing.html` (or the name of the file you saved)
4. The data should now be in a file named `output.csv`. You can upload that file to Google Sheets, open it with Excel, or do whatever else you need to do.
