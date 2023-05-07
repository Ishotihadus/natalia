# frozen_string_literal: true

require_relative 'natalia/services/joysound'
require_relative 'natalia/services/utamap'
require_relative 'natalia/version'

module Natalia
  class Entry
    def initialize(entry)
      @entry = entry
    end

    def respond_to_missing?(name, _include_private = false)
      @entry.key?(name)
    end

    def method_missing(name, *_args)
      @entry[name]
    end
  end

  class Song
    def initialize(entry)
      @entry = entry
    end

    def [](key)
      @entry[key]
    end

    def get
      Entry.new(@entry[:source].get(@entry[:id]))
    end

    def respond_to_missing?(name, _include_private = false)
      @entry.key?(name)
    end

    def method_missing(name, *_args)
      @entry[name]
    end
  end

  # 信頼できるソース順に並べる
  SERVICES = [
    Natalia::Utamap,
    Natalia::Joysound
  ].freeze

  def self.search_by_title(keyword, sort: :popularity_desc)
    entries = []
    SERVICES.each do |service|
      entries += service.search(keyword, type: :title, sort: sort)
    end
    entries.map {|entry| Song.new(entry)}
  end
end
