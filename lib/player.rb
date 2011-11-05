require 'open-uri'
require 'fileutils'

class Player
  attr_accessor :name 
  @@gamesDir = Dir.pwd + (ENV['TEST_DIR'] || '') + '/games/'
  
  def initialize(name)
    @name = name
    FileUtils.mkpath(@@gamesDir)
  end

  def url
    "http://alt.org/nethack/dumplogs.php?player=#{@name}"
  end

  def gamesFile
    @@gamesDir + "#{@name}.games"
  end

  def oldGames
    oldGames = File.exists?(self.gamesFile) ?  File.open(self.gamesFile, "r").readlines : []
    oldGames.each { |game| game.chomp! }
  end

  def newGames
    currentGames = []
    
    open(self.url) { |page_content|
      page_content.read.scan(/http.*userdata\/.*dumplog.*.txt/) { |url_string|
        currentGames = url_string.split(/href/).map { |url|
          url[/http:.*txt/]
        }
      }
    }

    newGames = currentGames - self.oldGames
  end

  def serializeGame(game)
    File.open(self.gamesFile, 'a') { |file| file.puts(game) }
  end
end
