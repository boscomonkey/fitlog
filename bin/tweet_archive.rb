#!/usr/bin/env ruby

require 'date'
require 'json'

class TweetArchive
  class << self
    def expand_full_text(tweet)
      urls = tweet['entities']['urls']
      full_text = tweet['full_text']

      all_versions = resolve_urls(urls, full_text)
      all_versions.last
    end

    def resolve_urls(urls, full_text)
      urls.each_with_object([full_text]) do |u_obj, text_arry|
        tco_url = u_obj['url']
        expa_url = u_obj['expanded_url']
        disp_url = u_obj['display_url']

        txt = text_arry.last
        regex = %r[#{tco_url}]
        replacement_html = "<a href=\"#{expa_url}\">#{disp_url}</a>"
        text_arry << txt.gsub(regex, replacement_html)
      end
    end
  end

  def initialize(fname = 'docs/data/tweets.js')
    js_str = File.read(fname)
    json_str = js_str.sub(/^window.YTD.tweets.part0 = /, '')
    @tweets = JSON.parse json_str
  end

  def to_blogger
    @tweets.map do |obj|
      tweet = obj['tweet']

      uuid = tweet['id_str']
      footer = "\n\n" + "Originally posted on <a href=\"https://twitter.com/twitfitlog/status/#{uuid}\">Twitter (#{uuid}).</a>"
      {
        id_str: uuid,
        created_at: DateTime.parse(tweet['created_at']),
        full_text: self.class.expand_full_text(tweet) + footer
      }
    end
  end
end
