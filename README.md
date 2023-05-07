# Natalia

日本語の歌詞掲載サイトから歌詞を取得するライブラリです。

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add natalia

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install natalia

## Usage

```rb
require 'natalia'

# 歌詞情報のエントリを取ってくる
songs = Natalia.search_by_title('永遠の花')

# 歌詞の取得
songs.first.get.lyrics
# => "窓あけたら　花瓶の花が\n風に誘われて　揺れたよ\nそう..."
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Ishotihadus/natalia.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
