# frozen_string_literal: true

require 'nokogiri'
require_relative '../utils'

module Natalia
  module Utamap
    SORT_MAP = {
      title: 1,
      title_desc: 2,
      popularity: 3,
      popularity_desc: 4,
      date: 5,
      date_desc: 6,
      artist: 7,
      artist_desc: 8
    }.freeze

    # @param [String] keyword キーワード（タイトル検索）、ID（それ以外）
    def self.search(keyword, type: :title, sort: :popularity_desc)
      sort = SORT_MAP[sort]
      raise ArgumentError, 'invalid sort type' unless sort
      raise ArgumentError, 'type must be :title, :artist, :lyricist, :composer, or :arranger' unless %i[title artist lyricist composer arranger].include?(type)

      entries = []
      (type == :title ? 1.. : [1]).each do |page|
        response =
          if type == :title
            Natalia::Utils.curl_get('https://www.uta-net.com/search/', { Keyword: keyword, Aselect: 2, Bselect: 3, sort: sort, pnum: page })
          else
            Natalia::Utils.curl_get("https://www.uta-net.com/#{type}/#{keyword}/#{sort}/")
          end
        break if response.code == '404'

        response.value

        doc = Nokogiri::HTML.parse(response.body)
        tbody = doc.at_css('tbody.songlist-table-body')
        tbody.css('tr').each do |tr|
          tds = tr.css('td')
          entries << {
            source: self,
            id: tds[0].at_css('a')['href'].match(%r{^/song/(\d+)/})[1],
            title: tr.at_css('span.songlist-title').content,
            artist: tds[1].at_css('a').content,
            artist_id: tds[1].at_css('a')['href'].match(%r{^/artist/(\d+)/})[1],
            lyricist: tds[2].at_css('a').content,
            lyricist_id: tds[2].at_css('a')['href'].match(%r{^/lyricist/(\d+)/})[1],
            composer: tds[3].at_css('a').content,
            composer_id: tds[3].at_css('a')['href'].match(%r{^/composer/(\d+)/})[1],
            arranger: tds[4].at_css('a').content,
            arranger_id: tds[4].at_css('a')['href'].match(%r{^/arranger/(\d+)/})[1],
            lyrics: tds[5].at_css('span.pc-utaidashi').content
          }
        end
      end

      entries
    end

    def self.get(id)
      response = Natalia::Utils.curl_get("https://www.uta-net.com/song/#{id}/")
      response.value

      doc = Nokogiri::HTML.parse(response.body)

      ret = {
        source: self,
        title: doc.at_css('div.song-infoboard h2').content,
        artist: doc.at_css('div.song-infoboard span[itemprop="byArtist name"]').content,
        artist_id: doc.at_css('div.song-infoboard a[itemprop="byArtist"]')['href'].match(%r{^/artist/(\d+)/})[1]
      }

      doc.at_css('div.song-infoboard a[itemprop="lyricist"]').tap do |e|
        next unless e

        ret[:lyricist] = e.content
        ret[:lyricist_id] = e['href'].match(%r{^/lyricist/(\d+)/})[1]
      end

      doc.at_css('div.song-infoboard a[itemprop="composer"]').tap do |e|
        next unless e

        ret[:composer] = e.content
        ret[:composer_id] = e['href'].match(%r{^/composer/(\d+)/})[1]
      end

      doc.at_css('div.song-infoboard a[itemprop="arranger"]').tap do |e|
        next unless e

        ret[:arranger] = e.content
        ret[:arranger_id] = e['href'].match(%r{^/arranger/(\d+)/})[1]
      end

      ret[:lyrics] = doc.at_css('div#kashi_area').children.map do |e|
        e.name == 'br' ? "\n" : e.content
      end.join.strip

      ret
    end
  end
end
