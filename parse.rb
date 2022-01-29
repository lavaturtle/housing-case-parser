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

    # Extract the case number
    headline = case_table.css('dt')
    case_number_raw = headline.children.first.text.strip

    # If this is not an 'LT-' case, skip it.
    next unless %r{LT-}.match?(case_number_raw)
    case_info[:case_no] = %r{(LT-\d+-\d+\/..) -}.match(case_number_raw)[1]

    # Extract the petitioner and respondent
    petitioner, respondent = headline.css('a').first.text.split(' vs. ')
    case_info[:petitioner] = petitioner
    case_info[:respondent] = respondent

    # Extract court part
    court_part_raw = case_table.css('dd').first.text
    part_raw = court_part_raw.split('/').last
    case_info[:court] = %r{Part: (.*)$}.match(part_raw)[1]

    # TODO: extract other info

    csv << COLUMNS.map{|col| case_info[col]}
    rows_written += 1
  end
end

puts "finished writing #{output_filename} with #{rows_written} rows"
