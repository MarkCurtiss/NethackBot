#!/usr/bin/env ruby

require 'open-uri'
require 'fileutils'

class Player
  attr_accessor :name 
  @@gamesDir = Dir.pwd + '/games/'
  @@dumpUrl = nil
  
  def initialize(name)
    @name = name
    @@dumpUrl = "http://alt.org/nethack/dumplogs.php?player=#{@name}"
     
    FileUtils.mkpath(@@gamesDir)
  end
  
  def setUrl(url)
    @@dumpUrl = url
  end

  def url
    @@dumpUrl
  end

  def gamesFile
    @@gamesDir + "#{@name}.games"
  end

  def newGames
    oldGames = File.exists?(self.gamesFile) ?  File.open(self.gamesFile, "r").readlines : []
    oldGames.each { |game| game.chomp! }
    currentGames = []

    open(self.url) { |page_content|
      page_content.read.scan(/http.*userdata\/.*dumplog.*.txt/) { |url_string|
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
