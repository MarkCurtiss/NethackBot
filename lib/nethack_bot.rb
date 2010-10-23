#!/usr/bin/env ruby

require 'logger'
require 'fileutils'
require 'player.rb'
require 'twitter_account.rb'

class NethackBot
  attr_accessor :players, :twitterName, :twitterPassword, :twitterAccount, :logger
  @@logDir = Dir.pwd + '/logs/'
  @@logName = @@logDir + 'nethack_bot.log'

  def initialize(configFile) 
    FileUtils.mkpath(@@logDir)
 
    File.open(configFile, 'r').each { |line|
      line.chomp!
      attribute, values = line.split('=')
      values = values.split(',') if values =~ /,/
      self.send("#{attribute}=", values) if self.respond_to?("#{attribute}")
    }

    self.players.map! { |playerName| Player.new(playerName) }
    self.twitterAccount = TwitterAccount.new(twitterName, twitterPassword)
    self.logger = Logger.new(@@logName, 'daily')
    self.logger.datetime_format = "%Y-%m-%d %H:%M:%S "
  end

  def run()
    self.logger.info('starting...')
    
    self.players.each { |player|
      self.logger.debug("#{player.gamesFile} already exists - comparing it to #{player.name}'s games to find new ones") if File.exist?(player.gamesFile)      

      player.newGames.each { |newGame|
        logger.debug("posting update for #{player.name}'s game #{newGame}")

	tinyGameLogUrl = getTinyUrl(newGame)
	deathMetadata = getDeathMetadata(newGame, player.name)

        postedToTwitterSuccessfully = self.twitterAccount.update("#{player.name.upcase} the #{deathMetadata[0]} died. Lvl: #{deathMetadata[1]}. Killer: #{deathMetadata[2]}. #{tinyGameLogUrl}")
        logger.debug("successfully posted to twitter?: #{postedToTwitterSuccessfully}")
        player.serializeGame(newGame) if postedToTwitterSuccessfully
      }
    }
    
    self.logger.info('done!')
  end

  def getDeathMetadata(gameLogUrl, playerName)
     commandString = '/usr/bin/curl ' + gameLogUrl
     rawLog = `#{commandString}`

     deathMetadata = Array.new     

     rawLog =~ /#{playerName} the (.*).../
     deathMetadata << $1 ? $1 : 'unknown'

     rawLog =~ /^You were level (.*) with a maximum/
     deathMetadata << $1 ? $1 : 'unknown'

     rawLog =~ /^Killer: (.*)/
     deathMetadata << $1 ? $1 : 'unknown'

     return deathMetadata
  end
  
  def getTinyUrl(gameLogUrl)
     return open('http://tinyurl.com/api-create.php?url=' + gameLogUrl, "UserAgent" => "Ruby-Wget").read
  end

end
