require 'helper'
require 'net/http'
require 'rexml/document'

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

    assert_equal('NBTEST the Healer died. Lvl: 1. Killer: sewer rat. http://tinyurl.com/yz88vt7', doc.root.text('status/text'))
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
end
