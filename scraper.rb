# -*- coding: utf-8 -*-

require 'json'
require 'mechanize'
require 'turbotlib'

SOURCE_URL = 'https://www.bot.or.th/English/FinancialInstitutions/WebsiteFI/Pages/instList.aspx'

agent = Mechanize.new

Turbotlib.log("Starting run...") # optional debug logging

page = agent.get(SOURCE_URL)

post_form = page.form_with(:id => 'aspnetForm')


doc = page.parser

selector = doc.css("div#MSOZoneCell_WebPartWPQ3 div.table-filter select")[0]
selector_id = selector['id']
selector_rx = /getComboA\(this,'([^']*)'\)/
selector_target = selector_rx.match(selector['onchange'])[1]

options = selector.css("option").map { |o| o['value'] }
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
replace_rx = /([^_]+)_([^_]+)_(.+)_([^_]+)_([^_]+)/
selector_target_new = selector_target.gsub(replace_rx, '\1$\2$\3$\4$\5')

target_value = selector_target_new + "|" + selector_target

target_field = post_form.field_with(name: "ctl00$ScriptManager")
target_field.value = target_value

post_form.add_field!("__EVENTARGUMENT", "filter|"+selector_id+"|1. Thai Commercial Banks")
post_form.add_field!("__ASYNCPOST", "true")

#post_form.fields.each do |f|
#   puts f.name
#end

puts post_form.request_data

headers = {
    'Content-Type'=> 'application/x-www-form-urlencoded',
    'User-Agent'=>"Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0",
}

np = agent.post(SOURCE_URL, post_form.request_data, headers)
puts np.body
