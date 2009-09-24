#!/usr/bin/ruby

require 'test/unit'
require 'nethack_bot.rb'

class NethackBotTest < Test::Unit::TestCase
  @@configFileName = '~.nethack_bot_test'
  
  def teardown
    File.unlink(@@configFileName) if File.exists?(@@configFileName)
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
