#!/usr/bin/env ruby

require 'action_view'
require 'google/apis/blogger_v3'
require 'json'

class BloggerImporter
  class << self
    def blogger(creds_fname = 'creds/twit-fit-log-dev-6f2e8d4cd0c7.json')
      blogger = Google::Apis::BloggerV3::BloggerService.new
      blogger.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(creds_fname),
      )

      blogger
    end

    def blogger_post(blog_id, post_id)
      bfg = blogger
      bfg.get_post(blog_id, post_id)
    end

    def from_file(json_filename)
      entries = load_file(json_filename)
      self.new(entries)
    end

    def load_file(json_filename)
      JSON.parse(File.read(json_filename))
    end
  end

  def initialize(entries_to_import)
    @entries = entries_to_import
    add_titles
  end

  def add_titles
    @entries.map do |entry|
      full_text = entry['full_text']
      title = strip_double_newline_to_end(full_text)
      entry['title'] = ActionView::Base.full_sanitizer.sanitize(title)

      entry
    end
  end

  # after titles have been added, select entries whose title length is greater than threshold
  def select_long_titles(length_threshold = 80)
    @entries.select do |entry|
      entry['title'].length > length_threshold
    end
  end

  def conform_long_titles(target_length = 72, ellipsis = '...')
    long_ones = select_long_titles(target_length + ellipsis.length)
    long_ones.map do |entry|
      entry['title'] = entry['title'][0..target_length - 1] + ellipsis
      entry
    end
  end

  def strip_double_newline_to_end(text)
    text.sub(/\n\n.*/m, '')
  end
end
