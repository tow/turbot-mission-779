# -*- coding: utf-8 -*-

require 'json'
require 'mechanize'
require 'turbotlib'

SOURCE_URL = 'https://www.bot.or.th/English/FinancialInstitutions/WebsiteFI/Pages/instList.aspx'

agent = Mechanize.new

Turbotlib.log("Starting run...") # optional debug logging

page = agent.get(SOURCE_URL)

post_form = page.form_with(:id => 'aspnetForm')

form_fields = post_form.fields

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

# set up appropriate form request ("all")

target_field = post_form.field_with(name: "ctl00$ScriptManager")
target_field.value = "ctl00$ctl72$g_4e681960_6197_4386_bea6_a1c8799fd31f$ctl00$UpdatePanel1|ctl00_ctl72_g_4e681960_6197_4386_bea6_a1c8799fd31f_ctl00_UpdatePanel1" # magic string. Can we inspect this from the HTML as well?

post_form.add_field!("__EVENTARGUMENT", "filter|ctl72_g_4e6813|1. Thai Commercial Banks")
post_form.add_field!("__ASYNCPOST", "true")

new_page = post_form.submit

puts new_page.body



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
