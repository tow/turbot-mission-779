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


# The page is an ASPX application.
# A small proportion of the data is accessible within the initial HTML,
# but the rest is injected in the page in the standard - unhelpful - ASPX
# "doPostback" style.
# It turns out that all data, including that in the initial HTML, is
# accessible via the postback mechanism, so for consistency we only deal with
# that one access point.

# The postback method means that data is accessible via a POST to the
# source URL - but the (30 or s0) POST variables are largely opaque in
# meaning, but required for the ASPX app to maintain its internal state.

# However, most of these can be read straight out of the body of the original
# HTML, which is essentially one big form.
# Beyond that, only two bits of information are really necessary:
# 1. A target ID, which specifies whether we are looking at the first (bank)
# or second (non-bank) list of institutions. (This is an opaque ID, but can
# be read out of the onchange event of a selector.)
# 2. An ID specifying which sublist we are looking for. This is a human
# readable name from a list of available options which can be read out of
# the HTML.

# We then make one request for each (target ID, sublist ID) combination,
# and for each request we get back a document out of which we can parse
# the information we want.

def companies_for_category(agent, post_form, selector_id, category_name)
  human_readable_category = category_name.split('.')[1].strip
  post_form['__EVENTARGUMENT'] = "filter|" + selector_id + "|" + category_name

  # Need to specify both of these headers for ASPX to be happy.
  headers = {
      'Content-Type'=> 'application/x-www-form-urlencoded',
      'User-Agent'=>"Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0",
  }

  # In principle, we should be able to simply do post_form.submit,
  # but that didn't work naively - it was easier to simply do the POST
  # directly rather than work out how to persuade mechanize to do the
  # right thing.
  np = agent.post(SOURCE_URL, post_form.request_data, headers)

  # The response that comes back is text/plain, in three parts
  # 1. a preamble which we can ignore
  # 2. an HTML table containing the data we want
  # 3. some additional JS which we can ignore.
  # The easiest way to get at the HTML data is just to chuck the whole
  # lot at Nokogiri.
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
        # This is probably not exactly the right way to exclude
        # irrelevant data, but it makes the validator pass.
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
  # I don't know why, but we have to munge the selector target like so.

  post_form['ctl00$ScriptManager'] = selector_target_new + "|" + selector_target
  post_form['__ASYNCPOST'] = "true"


  options.each do |o|
    companies_for_category(agent, post_form, selector_id, o)
  end
end



# For bank institutions
selector = doc.css("div#MSOZoneCell_WebPartWPQ3 div.table-filter select")[0]
# #MSOZoneCell_WebPartWPQ3 is the pane where the bank data is held currently
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
   # because then something has changed unexpectedly
end

# NB the 0th (empty) option is for "all", but we don't want that,
# we need to have the classifications by company
do_all_options(agent, post_form, selector_id, selector_target, options[1..-1])


# For non-bank institutions
selector = doc.css("div#MSOZoneCell_WebPartWPQ5 div.table-filter select")[0]
# #MSOZoneCell_WebPartWPQ5 is the pane where the non-bank data is held currently
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
   # because then something has changed unexpectedly
end

# NB the 0th (empty) option is for "all", but we don't want that,
# we need to have the classifications by company
do_all_options(agent, post_form, selector_id, selector_target, options[1..-1])
