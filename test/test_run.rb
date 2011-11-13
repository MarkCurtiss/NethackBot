require 'helper'

#this test actually posts to a twitter account.  for this reason, it is not included
#as part of the test suite.  it's intended to be used a sanity check to see if NethackBot
#will work on your system (necessary binaries are in the right place, it has adequate
#permissions, etc).

#INTERESTING FACT
#before this test, the only way to test NethackBot was to actually log into one of the
#watched alt.org player accounts and die, then see if the Twitter account was updated.

class NethackBotTestRun < Test::Unit::TestCase
  @@configFileName = File.expand_path('~/.nethack_bot_test_run')
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
      file.puts('consumer_key=dTYnNFT5dcmj9yXGMdtw')
      file.puts('consumer_secret=D2OmfcdMaBkKQMtzeTUmHWIXZdXbmndLPjjZY0PdA')
      file.puts('oauth_token=75188583-pNrTjuTjQE6b8TPK03WN7S0t1PoIqkPxw8zuD3DRc')
      file.puts('oauth_token_secret=nc6Y4vSRLAA2vd1G82zjmnS7iUHRgJ7YbB9IZew')
    }

    testBot = NethackBot.new(@@configFileName)
    testBot.run

    @@players.each { |playerName|
      player = Player.new(playerName)
      assert(File.exists?(player.gamesFile), "#{playerName} does not have a games file")

      #delete the last game and overwrite the gamesFile
      #this will cause the last game to appear new and get tweeted
      newFileContents = File.open(player.gamesFile).readlines
      newFileContents.pop

      File.open(player.gamesFile, 'w') { |f|
        f.puts(newFileContents)
      }
    }

    testBot.run
  end
end
