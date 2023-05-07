# frozen_string_literal: true

require 'nokogiri'
require 'time'
require_relative '../utils'

module Natalia
  module JLyric
    # sort という概念はないっぽい
    def self.search(keyword, type: :title, sort: :popularity_desc)
      case type
      when :title
        search_by_title(keyword)
      when :artist
        search_by_artist(keyword, sort: sort)
      else
        raise ArgumentError, "unsupported search type `#{type}`"
      end
    end

    def self.search_by_title(keyword)
      entries = []
      (1..).each do |page|
        response =
          Natalia::Utils.curl_get('https://search2.j-lyric.net/index.php', {
                                    kt: keyword,
                                    ct: '2', # kt 検索方法 (0: 前方, 1: 完全, 2: 中間, 3: 後方)
                                    search: '検索', # 謎
                                    ex: 'on', # 謎
                                    ca: '2', # ka 検索方法
                                    cl: '2', # kl 検索方法
                                    p: page
                                  })
        response.value

        doc = Nokogiri::HTML.parse(response.body)
        table = doc.css('div#bas div#cnt div#mnb > div.bdy')
        break if table.empty?

        table.each do |body|
          entries << {
            source: self,
            id: body.at_css('p.mid a')['href'].match(%r{/artist/(.+)\.html\z})[1],
            title: body.at_css('p.mid a').content,
            artist: body.css('p.sml')[0].at_css('a').content,
            artist_id: body.css('p.sml')[0].at_css('a')['href'].match(%r{/artist/(.+)/\z})[1]
          }
        end
      end

      entries
    end

    def self.search_by_artist(artist_id, sort: :popularity_desc)
      response = Natalia::Utils.curl_get("https://j-lyric.net/artist/#{artist_id}/")
      response.value

      doc = Nokogiri::HTML.parse(response.body)
      artist_name = doc.at_css('div#mnb div.cnt div.cap h2').content.match(/\A(.+)の歌詞リスト\z/)[1]
      table = doc.css('div#bas div#cnt div#mnb div.bdy[id^=ly]')

      entries = table.map do |row|
        order, date, popularity = row.css('input[type=hidden]').map {|e| e['value']}
        {
          source: self,
          id: row.at_css('p.ttl a')['href'].match(%r{/artist/(.+)\.html\z})[1],
          title: row.at_css('p.ttl a').content,
          artist: artist_name,
          artist_id: artist_id,
          order: order.to_i,
          date: Time.parse("#{date} JST"),
          popularity: -popularity.to_i
        }
      end.compact

      case sort
      when :title
        entries.sort_by {|e| e[:order]}
      when :title_desc
        entries.sort_by {|e| -e[:order]}
      when :popularity
        entries.sort_by {|e| e[:popularity]}
      when :popularity_desc
        entries.sort_by {|e| -e[:popularity]}
      when :date
        entries.sort_by {|e| e[:date]}
      when :date_desc
        entries.sort_by {|e| -e[:date].to_i}
      when :artist, :artist_desc
        entries
      else
        raise ArgumentError, "unsupported sort type `#{sort}`"
      end
    end

    def self.get(id)
      response = Natalia::Utils.curl_get("https://j-lyric.net/artist/#{id}.html")
      response.value

      doc = Nokogiri::HTML.parse(response.body)

      smls = doc.css('div#mnb div.lbdy p.sml')

      ret = {
        source: self,
        id: id,
        title: doc.at_css('div#mnb div.cap h2').content.match(/\A「(.+)」歌詞\z/)[1],
        artist: smls[0].at_css('a').content,
        artist_id: smls[0].at_css('a')['href'].match(%r{/artist/(.+)/\z})[1]
      }

      smls[1..].each do |e|
        content = e.content
        ret[:lyricist] = content.match(/作詞：(.+)/)[1] if content.start_with?('作詞：')
        ret[:composer] = content.match(/作曲：(.+)/)[1] if content.start_with?('作曲：')
      end

      ret[:lyrics] = doc.at_css('p#Lyric').children.map do |e|
        e.name == 'br' ? "\n" : e.content
      end.join.strip

      ret
    end
  end
end
