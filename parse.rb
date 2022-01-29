#! /usr/bin/env ruby

require 'nokogiri'
require 'csv'

input_filename = ARGV[0]
output_filename = 'output.csv'

COLUMNS = %i(court petitioner case_no def_attorney respondent address court_date outcome marshall_assigned marshall)

parsed_html = File.open(input_filename, 'r') do |fh|
                Nokogiri::HTML.parse(fh)
              end

case_list_section = parsed_html.css('table td:nth-child(2) table > tbody > tr:nth-child(4) > td')
case_tables = case_list_section.css('table')

rows_written = 0
CSV.open(output_filename, 'w') do |csv|
  csv << COLUMNS

  case_tables.each do |case_table|
    case_info = {}

    # Extract the case number, petitioner, and respondent
    headline = case_table.css('dt')
    case_number_raw = headline.children.first.text.strip
    case_info[:case_no] = %r{(LT-\d+-\d+\/..) -}.match(case_number_raw)[1]
    parties = headline.css('a').first.text.split(' vs. ')
    case_info[:petitioner] = parties.first
    case_info[:respondent] = parties.last

    # TODO: extract other info

    csv << COLUMNS.map{|col| case_info[col]}
    rows_written += 1
  end
end

puts "finished writing #{output_filename} with #{rows_written} rows"
