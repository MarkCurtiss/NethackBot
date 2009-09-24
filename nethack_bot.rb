#!/usr/bin/env ruby

require 'logger'
require 'player.rb'
require 'twitter_account.rb'

class NethackBot
  attr_accessor :players, :twitterName, :twitterPassword, :twitterAccount, :logger
  @@logDir = Dir.pwd + '/logs/'
  @@logName = @@logDir + 'nethack_bot.log'

  def initialize(configFile) 
    File.mkpath(@@logDir)
 
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
        postedToTwitterSuccessfully = self.twitterAccount.update("#{player.name.upcase} DIED! #{newGame}")
        logger.debug("successfully posted to twitter?: #{postedToTwitterSuccessfully}")
        player.serializeGame(newGame) if postedToTwitterSuccessfully
      }
    }
    
    self.logger.info('done!')
  end
end

if __FILE__ == $0 
  configFileName = ARGV[0] || File.expand_path('~/.nethack_bot')
  nethackBot = NethackBot.new(configFileName)
  nethackBot.run
end
