#!/usr/bin/env ruby

require 'test/unit'
require 'net/http'
require 'rexml/document'
require 'nethack_bot.rb'

class NethackBotTest < Test::Unit::TestCase
  @@configFileName = '.nethack_bot_test'
  @@twitterName = 'sswtestnb' 
  @@twitterPass = 'testPassword' 
  @@playerName = 'nbTest' 
  @@playerGameFile = Dir.pwd + '/games/' + @@playerName + '.games'
  
  def teardown
    File.unlink(@@playerGameFile) if File.exists?(@@playerGameFile)
    File.unlink(@@configFileName) if File.exists?(@@configFileName)
  end

  def test_updates_twitter_account_with_correct_message
    File.open(@@configFileName, 'w') { |file|
      file.puts('players=' + @@playerName + ',whydoineedthis')
      file.puts('twitterName=sswtestnb')
      file.puts('twitterPassword=testPassword')
    }

    player1 = Player.new(@@playerName)

    twitterAccount = TwitterAccount.new(@@twitterName, @@twitterPass)
    testBot = NethackBot.new(@@configFileName)
    testBot.run()

    doc = REXML::Document.new(Net::HTTP.get_response(URI.parse("http://twitter.com/users/show/" + @@twitterName + ".xml")).body)

    assert_equal('RTKFAN16 the Demigoddess died. Lvl: 29. Killer: ascended. http://tinyurl.com/ybvzbsy', doc.root.text('status/text'))
  end
  
  def test_reads_dot_nethack_bot_file_in_homedir_for_configuration
    File.open(@@configFileName, 'w') { |file|
      file.puts('players=testPlayer1,testPlayer2')
      file.puts('twitterName=testAccount')
      file.puts('twitterPassword=testPassword')
    }

    testBot = NethackBot.new(@@configFileName)

    player1 = Player.new('testPlayer1')
    player2 = Player.new('testPlayer2')
    twitterAccount = TwitterAccount.new('testAccount', 'testPassword')

    assert_equal([player1, player2].map { |x| x.name }, testBot.players.map { |y| y.name });
    assert_equal(twitterAccount.userName, testBot.twitterAccount.userName)
    assert_equal(twitterAccount.password, testBot.twitterAccount.password)
  end
  
  def test_parses_death_logs_correctly
    File.open(@@configFileName, 'w') { |file|
      file.puts('players=testPlayer1,testPlayer2')
      file.puts('twitterName=testAccount')
      file.puts('twitterPassword=testPassword')
    }

    testBot = NethackBot.new(@@configFileName)
    deathMetadata = testBot.getDeathMetadata('http://alt.org/nethack/userdata/rtkfan16/dumplog/1264901949.nh343.txt', 'rtkfan16')

    assert_equal(deathMetadata, [ "Demigoddess", "29", "ascended" ])
    
    deathMetadata = testBot.getDeathMetadata('http://alt.org/nethack/userdata/zew/dumplog/1263974864.nh343.txt', 'zew')
    
    assert_equal(deathMetadata, [ "Demigoddess", "23", "ascended" ])
    
    deathMetadata = testBot.getDeathMetadata('http://alt.org/nethack/userdata/zew/dumplog/1265693780.nh343.txt', 'zew')
    
    assert_equal(deathMetadata, ["Knight", "7", "gnome lord"])
  end
  
  def test_does_not_serialize_logs_that_arent_fully_entered
    File.open(@@configFileName, 'w') { |file|
      file.puts('players=rtkfan16,testPlayer1')
      file.puts('twitterName=sswtestnb')
      file.puts('twitterPassword=testPassword')
    }

    testPlayer = Player.new('rtkfan16')
    testBot = NethackBot.new(@@configFileName)
    
    testPlayer.setUrl('http://scottwainstock.com/nethackbot/userdata/rtkfan16/dumplog')

    testBot.run()
    assert_equal(1, testPlayer.newGames().size)
    
    testBot.run()
    assert_equal(1, testPlayer.newGames().size)

    assert_equal(testPlayer.newGames()[0], 'http://scottwainstock.com/nethackbot/userdata/rtkfan16/dumplog/1264901949.nh343.txt');
  end
end
