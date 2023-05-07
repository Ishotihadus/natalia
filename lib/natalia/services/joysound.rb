# frozen_string_literal: true

require 'json'
require_relative '../utils'

module Natalia
  module Joysound
    SORT_MAP = {
      title: %w[name asc].freeze,
      title_desc: %w[name desc].freeze,
      popularity: %w[popular asc].freeze,
      popularity_desc: %w[popular desc].freeze,
      date: %w[new asc].freeze,
      date_desc: %w[new desc].freeze,
      artist: %w[artist asc].freeze,
      artist_desc: %w[artist desc].freeze
    }.freeze

    KIND_MAP = {
      title: 'song',
      artist: 'selArtist',
      service: 'selService' # 配信機種的なやつ?
    }.freeze

    def self.search(keyword, type: :title, sort: :popularity_desc)
      sort = SORT_MAP[sort]
      raise ArgumentError, 'invalid sort type' unless sort

      response = Natalia::Utils.curl_post('https://mspxy.joysound.com/Common/ContentsList') do |request|
        request.content_type = 'application/x-www-form-urlencoded; charset=UTF-8'
        request['X-Jsp-App-Name'] = '0000800'
        request.set_form_data(
          format: 'all',
          kindCnt: '1', # この数の分だけ kind1, word1, match1 を指定できるっぽい
          start: '1',
          count: '999',
          sort: sort[0],
          order: sort[1],
          kind1: KIND_MAP[type],
          word1: keyword,
          match1: type == :title ? 'partial' : 'exact', # partial / front / exact
          apiVer: '1.0'
        )
      end

      response.value
      json = JSON.parse(response.body.force_encoding('utf-8'))
      contents_list = json['contentsList']

      contents_list.select! do |e|
        e['serviceTypeList'].any? do |service|
          # なんかこの 2 つを除外して残らないと歌詞が配信されていないっぽい?
          service['serviceType'] != '001000000' && service['serviceType'] != '100000000'
        end
      end

      contents_list.map do |e|
        {
          source: self,
          id: e['naviGroupId'],
          title: e['songName'],
          artist: e['artistName'],
          artist_id: e['artistId'],
          lyricist: e['lyricist'],
          composer: e['composer'],
          raw_data: e
        }
      end
    end

    def self.get(id)
      response = Natalia::Utils.curl_post('https://mspxy.joysound.com/Common/Lyric') do |request|
        request.content_type = 'application/x-www-form-urlencoded; charset=UTF-8'
        request['X-Jsp-App-Name'] = '0000800'
        request.set_form_data(
          kind: 'naviGroupId',
          selSongNo: id,
          interactionFlg: '0',
          apiVer: '1.0'
        )
      end

      return nil if response.code == '404'

      response.value
      json = JSON.parse(response.body.force_encoding('utf-8'))

      {
        source: self,
        id: json['naviGroupId'],
        title: json['songName'],
        artist: json['artistName'],
        artist_id: json['artistId'],
        lyricist: json['lyricist'],
        composer: json['composer'],
        lyrics: json['lyricList']&.find {|e| e['statusCode'] == '1'}&.[]('lyric')&.strip,
        raw_data: json
      }
    end
  end
end
