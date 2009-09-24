#!/usr/bin/env ruby

require 'open-uri'
require 'yaml'

class Player
  attr_accessor :name 
  
  def initialize(name)
    @name = name
  end

  def url
    "http://alt.org/nethack/dumplogs.php?player=#{@name}"
  end

  def gamesFile
    "/Users/markcurtiss/nethack_bot/#{@name}.games"
  end
  
  def newGames
    oldGames = File.exists?(self.gamesFile) ?  File.open(self.gamesFile, "r").readlines : []
    oldGames.each { |game| game.chomp! }
    currentGames = []
    
    open(self.url) { |page_content|
      page_content.string.scan(/http.*userdata\/.*dumplog.*.txt/) { |url_string|
        currentGames = url_string.split(/href/).map { |url|
          url[/http:.*txt/]
        }
      }
    }

    newGames = currentGames - oldGames
  end

  def serializeGame(game)
    File.open(self.gamesFile, 'a') { |file| file.puts(game) }
  end
end
