# -*- coding: utf-8 -*-

require 'json'
require 'mechanize'
require 'turbotlib'

SOURCE_URL = 'https://www.bot.or.th/English/FinancialInstitutions/WebsiteFI/Pages/instList.aspx'

agent = Mechanize.new

Turbotlib.log("Starting run...") # optional debug logging

page = agent.get(SOURCE_URL)

form_fields = page.form_with(:id => 'aspnetForm').fields

form_fields.each do |f|
   puts f.name, f.value
end

doc = page.parser

options = doc.css("div#MSOZoneCell_WebPartWPQ3 div.table-filter option").map { |o| o['value'] }

puts options

expected_options = ["",
"1. Thai Commercial Banks",
"2. Retail Banks",
"3. Subsidiary",
"4. Foreign Banks Branches",
"5. Finance Companies",
"6. Credit Fonciers",
"7. Foreign Bank Representatives",
"8. Assets Management Companies (AMC)",
"9. Specialized Financial Institutions",
]

if options != expected_options
   raise RuntimeError
end

#get all the relevant input fields

#that is everything under form input

#get all the relevant options 

#(1...20).each do |n|
#  data = {
#    number: n,
#    company: "Company #{n} Ltd",
#    message: "Hello #{n}",
#    sample_date: Time.now,
#    source_url: "http://somewhere.com/#{n}"
#  }
  # The Turbot specification simply requires us to output lines of JSON
#  puts JSON.dump(data)
#end
