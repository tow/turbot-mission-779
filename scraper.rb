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

options = doc.css("div#MSOZoneCell_WebPartWPQ3 div.table-searchbox select options")

options.each { |o| puts o }

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
