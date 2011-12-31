require 'open-uri'

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

  def current_games
    current_games = []

    open(self.url) { |page_content|
      page_content.read.scan(/http.*userdata\/.*dumplog.*.txt/) { |url_string|
        game_urls = url_string.split(/href/).map { |url| url[/http:.*txt/] }
        current_games = game_urls.map { |url| Game.new(url) }
      }
    }
    return current_games
  end

  def newGames
    old_games = self.oldGames
    current_games = self.current_games

    #it'd be more elegant to do new_games = current_games - old_games but that would be slower,
    #since array arithmetic hashes the elements.  this is n^2 but equality testing will be faster
    #most of the time (see Game#hash and Game#==)
    new_games = []
    current_games.each { |g|
      new_games.push(g) unless old_games.include?(g)
    }
    return new_games
  end

  def serializeGame(game)
    File.open(self.gamesFile, 'a') { |file| file.puts(game.url) }
  end

  def new?
    self.oldGames.empty?
  end
end
