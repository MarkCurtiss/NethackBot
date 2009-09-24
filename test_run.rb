#!/usr/bin/env ruby

require 'test/unit'
require 'player.rb'

#this test actually posts to a twitter account.  for this reason, it is not included
#as part of the test suite.  it's intended to be used a sanity check to see if NethackBot
#will work on your system (necessary binaries are in the right place, it has adequate  
#permissions, etc).

#INTERESTING FACT
#before this test, the only way to test NethackBot was to actually log into one of the 
#watched alt.org players and die, then see if the Twitter account was updated.

class NethackBotTestRun < Test::Unit::TestCase
  @@configFileName = '~.nethack_bot_test_run'
  @@players = ['nbTest', 'cultofluna']

  def teardown
    File.unlink(@@configFileName) if File.exists?(@@configFileName)
    @@players.each { |playerName|
      player = Player.new(playerName)
      File.unlink(player.gamesFile) if File.exists?(player.gamesFile)
    }
  end

  def test_run
    File.open(@@configFileName, 'w') { |file|
      file.puts('players=nbTest,cultofluna')
      file.puts('twitterName=twnbtest')
      file.puts('twitterPassword=dgdoc3vdcv')
    }

    output = `./nethack_bot.rb #{@@configFileName}`
    puts(output)

    @@players.each { |playerName|
      player = Player.new(playerName)
      assert(File.exists?(player.gamesFile), "#{playerName} does not have a games file")
    }
  end
end
