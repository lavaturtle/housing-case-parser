#! /usr/bin/env ruby

require 'csv'
require 'nokogiri'
require 'time'

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

  current_date = nil

  case_tables.each do |case_table|
    # See if there's a date header at the top of this listing
    date_header = case_table.css('th')
    if date_header.any?
      current_date = Date.parse(date_header.text)
    end

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

    # Does the respondent have an attorney?
    def_has_attorney = case_table.css('dd').any?{|node| node.text.include?('Defendant Attorney:')}
    case_info[:def_attorney] = def_has_attorney ? 'Yes' : 'No'

    # Extract the time and combine it with the date
    time_el = case_table.css('dd').find{|node| node.text.start_with?('Time:')}
    time_string = %r{Time: (.*)}.match(time_el.text)[1]
    case_datetime = Time.parse(time_string, current_date)
    case_info[:court_date] = case_datetime.iso8601

    csv << COLUMNS.map{|col| case_info[col]}
    rows_written += 1
  end
end

puts "finished writing #{output_filename} with #{rows_written} rows"
