# frozen_string_literal: true

require 'require_all'
require 'scraped'
require 'scraperwiki'
require 'active_support'
require 'active_support/core_ext/string'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

# require_rel 'lib'

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

class ParisCouncilPage < Scraped::HTML
  field :councillors do
    noko.xpath('.//table[3]/tr[td]').map do |tr|
      fragment(tr => Councillor)
    end
  end
end

class Councillor < Scraped::HTML
  field :id do
    name.parameterize
  end

  field :name do
    name_text.tidy
  end

  field :party_name do
    noko.xpath('td[3]/a/@title').text.tidy
  end

  field :party_code do
    noko.xpath('td[3]').text.tidy.gsub(/\[.+?\]$/, '')
  end

  field :area_name do
    noko.xpath('td[4]/a/@title').text.tidy
  end

  field :area_id do
    a = noko.xpath('td[4]/a/abbr/text()|td[4]/a/text()').text.tidy
    binding.pry if a.to_s.empty?
    a
  end

  private

  def name_text
    if noko.xpath('td[1]/a').any?
      noko.xpath('td[1]/a').text
    else
      noko.xpath('td[1]/text()').text
    end
  end
end

wikipedia_url = 'https://fr.wikipedia.org/wiki/Liste_des_conseillers_de_Paris'

page = scrape(wikipedia_url => ParisCouncilPage)

page.councillors.each do |c|
  p c.to_h
  ScraperWiki.save_sqlite([:id], c.to_h)
end
