require 'open-uri'
require 'fileutils'

class Player
  attr_accessor :name
  GAMES_DIR = Dir.pwd + (ENV['TEST_DIR'] || '') + '/games/'

  def initialize(name)
    @name = name
    FileUtils.mkpath(GAMES_DIR)
  end

  def url
    "http://alt.org/nethack/dumplogs.php?player=#{@name}"
  end

  def gamesFile
    GAMES_DIR + "#{@name}.games"
  end

  def oldGames
    old_game_urls = File.exists?(self.gamesFile) ?  File.open(self.gamesFile, "r").readlines : []
    return old_game_urls.map { |url| Game.new(url.chomp!) }
  end

  def newGames
    currentGames = []

    open(self.url) { |page_content|
      page_content.read.scan(/http.*userdata\/.*dumplog.*.txt/) { |url_string|
        game_urls = url_string.split(/href/).map { |url| url[/http:.*txt/] }
        currentGames = game_urls.map { |url| Game.new(url) }
      }
    }

    newGames = currentGames - self.oldGames
  end

  def serializeGame(game)
    File.open(self.gamesFile, 'a') { |file| file.puts(game.url) }
  end

  def new?
    self.oldGames.empty?
  end
end
