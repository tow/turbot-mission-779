# -*- coding: utf-8 -*-

require 'json'
require 'mechanize'
require 'nokogiri'
require 'turbotlib'

SOURCE_URL = 'https://www.bot.or.th/English/FinancialInstitutions/WebsiteFI/Pages/instList.aspx'

agent = Mechanize.new

Turbotlib.log("Starting run...") # optional debug logging

page = agent.get(SOURCE_URL)

post_form = page.form_with(:id => 'aspnetForm')

doc = page.parser

selector_rx = /getComboA\(this,'([^']*)'\)/


def companies_for_category(agent, post_form, selector_id, category_name)
  human_readable_category = category_name.split('.')[1].strip
  post_form['__EVENTARGUMENT'] = "filter|" + selector_id + "|" + category_name

  headers = {
      'Content-Type'=> 'application/x-www-form-urlencoded',
      'User-Agent'=>"Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0",
  }

  np = agent.post(SOURCE_URL, post_form.request_data, headers)

  page = Nokogiri::HTML(np.body)

  now = Time.now

  page.css("tr")[2..-1].each do |tr|
    tds = tr.css("td")
    contact_data = {
      "registered_address" => tds[2].xpath("text()")[0].text.strip,
      "website" => tds[1].xpath("div/a/@href"),
      "telephone_number" => tds[2].xpath("text()")[1].text[4..-1].strip,
      "fax_number" => tds[2].xpath("text()")[2].text[4..-1].strip
    }

    datum = {
      "confidence" => "LOW", # until I understand the schema better
      "licence_holder" => {
        "entity_type" => "company",
        "entity_properties" => {
          "name" => tds[1].xpath("div/text()")[0].text.strip
        },
      },
      "jurisdiction_of_licence" => "th",
      "licence_issuer" => {
        "jurisdiction" => "Thailand",
        "name" =>"Bank of Thailand",
      },
      "source_url" => SOURCE_URL,     # mandatory field
      "sample_date" => now,       # mandatory field
      "retrieved_at" => now,       # mandatory field
      "category" => ["Financial"],
      "permissions" => [
        { "activity_name" => human_readable_category }
      ],
    }

    contact_data.each_pair do |k, v|
      if v.size > 4
        datum['licence_holder']['entity_properties'][k] = v
      end
    end

    puts JSON.dump(datum)
  end
end


def do_all_options(agent, post_form, selector_id, selector_target, options)
  # set up appropriate form request ("all")
  replace_rx = /([^_]+)_([^_]+)_(.+)_([^_]+)_([^_]+)/
  selector_target_new = selector_target.gsub(replace_rx, '\1$\2$\3$\4$\5')

  post_form['ctl00$ScriptManager'] = selector_target_new + "|" + selector_target
  post_form['__ASYNCPOST'] = "true"


  options.each do |o|
    companies_for_category(agent, post_form, selector_id, o)
  end
end



# For bank institutions
selector = doc.css("div#MSOZoneCell_WebPartWPQ3 div.table-filter select")[0]
selector_id = selector['id']
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

do_all_options(agent, post_form, selector_id, selector_target, options[1..-1])


# For non-bank institutions
selector = doc.css("div#MSOZoneCell_WebPartWPQ5 div.table-filter select")[0]
selector_id = selector['id']
selector_target = selector_rx.match(selector['onchange'])[1]

options = selector.css("option").map { |o| o['value'] }
expected_options = ["",
"1. Credit Card Company",
"2. Personal Loan Company",
"3. Nano Finance",
]
if options != expected_options
   raise RuntimeError
end

do_all_options(agent, post_form, selector_id, selector_target, options[1..-1])
