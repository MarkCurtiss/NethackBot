require 'rubygems'
require 'bundler/setup'

require 'logger'
require 'fileutils'
require 'twitter'
require 'player'

class NethackBot
  attr_accessor :players, :consumer_key, :consumer_secret, :oauth_token, :oauth_token_secret, :twitterAccount, :logger, :silent

  @@logDir = Dir.pwd + (ENV['TEST_DIR'] || '') + '/logs/'
  @@logName = @@logDir + 'nethack_bot.log'

  def initialize(configFile, options = {})
    @silent = options[:silent] || false

    FileUtils.mkpath(@@logDir)

    File.open(configFile, 'r').each { |line|
      line.chomp!
      attribute, values = line.split('=')
      values = values.split(',') if values =~ /,/
      self.send("#{attribute}=", values) if self.respond_to?("#{attribute}")
    }

    @players = [ @players ].flatten #convert string to an array in case we only have one player
    @players.map! { |playerName| Player.new(playerName) }

    @logger = Logger.new(@@logName, 'daily')
    @logger.datetime_format = "%Y-%m-%d %H:%M:%S "

    unless (@silent)
      Twitter.configure do |config|
        config.consumer_key = self.consumer_key
        config.consumer_secret = self.consumer_secret
        config.oauth_token = self.oauth_token
        config.oauth_token_secret = self.oauth_token_secret
      end
      @twitterAccount = Twitter.new
    end
  end

  def run()
    @logger.info('starting...')
    @logger.info("running in #{@silent ? 'silent' : 'normal'} mode")

    @players.each { |player|
      playerIsNew = player.new? #performance hack so we don't keep re-reading the player's games file as we loop over their new games
      if (playerIsNew)
        @logger.debug("#{player.name} is new - their games will be logged but not posted to twitter")
      else
        @logger.debug("#{player.name} already exists - their new games will be posted to twitter")
      end

      @logger.debug("looking for games for #{player.name}...")

      player.newGames.each { |newGame|
        if (@silent || playerIsNew)
          @logger.debug("logging #{player.name}'s game #{newGame}")
          player.serializeGame(newGame)
        else
          deathMetadata = getDeathMetadata(newGame, player.name)

          if (deathMetadata.empty?)
            #i strongly suspect but haven't been able to prove that this happens when the URL's been posted to nethack.alt.org but
            #the actual dumplog hasn't been fully populated yet.  coming back to the game later should fix it.
            @logger.debug("skipping this game as we were unable to parse to it correctly - will try again later")
          else
            @logger.debug("posting update for #{player.name}'s game #{newGame}")
            postedToTwitterSuccessfully = ! @twitterAccount.update(self.statusUpdate(player, newGame, deathMetadata)).nil?
            @logger.debug("successfully posted to twitter?: #{postedToTwitterSuccessfully}")
            player.serializeGame(newGame) if postedToTwitterSuccessfully
          end
        end
      }
    }

    @logger.info('done!')
  end

  def statusUpdate(player, url, deathMetadata)
    playerDied = ! /(ascended|escaped|quit)/.match(deathMetadata[:killer])
    playerAscended = /ascended/.match(deathMetadata[:killer])
    endCondition = ''

    if (playerAscended)
      endCondition = 'ascended!'
    elsif (playerDied)
      endCondition = 'died.'
    else
      endCondition = deathMetadata[:killer] + '.'
    end

    statusUpdate = "#{player.name.upcase} the #{deathMetadata[:class]} #{endCondition} "
    statusUpdate += "Lvl: #{deathMetadata[:level]}. "
    statusUpdate += "Killer: #{deathMetadata[:killer]}. " if playerDied
    statusUpdate += url
  end

  def getDeathMetadata(gameLogUrl, playerName)
    death_text = read_url(gameLogUrl)

    deathMetadata = Hash.new

    death_text =~ /#{playerName}, \w+ \w+ \w+ (.*)/
    deathMetadata[:class] = $1 if $1

    death_text =~ /^You were level (.*) with a maximum/
    deathMetadata[:level] = $1 if $1

    death_text =~ /^Killer: (.*)/
    deathMetadata[:killer] = $1 if $1

    if (deathMetadata.keys.size < 3)
      @logger.debug("parsed the following incomplete death metadata: #{deathMetadata}")
      deathMetadata.clear
    end

    return deathMetadata
  end

  protected
  def read_url(game_log_url)
     command_string = '/usr/bin/curl --silent ' + game_log_url
     return `#{command_string}`.encode('ASCII', :invalid => :replace)
  end
end
