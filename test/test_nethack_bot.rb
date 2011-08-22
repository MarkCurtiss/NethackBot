require 'helper'

class NethackBotTest < Test::Unit::TestCase
  @@configFileName = '.nethack_bot_test'
  @@twitterName = 'sswtestnb'
  @@twitterPass = 'testPassword'
  @@playerName = 'nbTest'
  @@playerGameFile = Dir.pwd + (ENV['TEST_DIR'] || '') + '/games/' + @@playerName + '.games'

  def teardown
    File.unlink(@@playerGameFile) if File.exists?(@@playerGameFile)
    File.unlink(@@configFileName) if File.exists?(@@configFileName)
  end

  def test_status_update
    File.open(@@configFileName, 'w') { |file|
      file.puts('players=' + @@playerName + ',bug')
    }

    testBot = NethackBot.new(@@configFileName)

    twitterClient = testBot.twitterAccount

    #okay, maybe it's time to switch to rspec
    twitterClient.instance_variable_set(:@statusUpdates, [])
    def twitterClient.update(status)
      @statusUpdates.push(status)
    end

    testBot.run

    assert_equal('NBTEST the Healer died. Lvl: 1. Killer: sewer rat. http://tinyurl.com/2g43rz3',
                 twitterClient.instance_variable_get(:@statusUpdates).last)
  end

  def test_silent_option_logs_games_but_doesnt_tweet
    File.open(@@configFileName, 'w') { |file|
      file.puts('players=' + @@playerName + ',bug')
    }

    testBot = NethackBot.new(@@configFileName, :silent => true)

    twitterClient = testBot.twitterAccount

    twitterClient.instance_variable_set(:@was_called, false)
    def twitterClient.update(status)
      @was_called = true
    end

    testBot.run

    assert_equal(false, twitterClient.instance_variable_get(:@was_called));
  end

  def test_reads_dot_nethack_bot_file_in_homedir_for_configuration
    File.open(@@configFileName, 'w') { |file|
      file.puts('players=testPlayer1,testPlayer2')
      file.puts('consumer_key=test_key')
      file.puts('consumer_secret=test_secret')
      file.puts('oauth_token=test_token')
      file.puts('oauth_token_secret=test_token_secret')
    }

    testBot = NethackBot.new(@@configFileName)

    player1 = Player.new('testPlayer1')
    player2 = Player.new('testPlayer2')

    Twitter.configure do |config|
      config.consumer_key = 'test_key'
      config.consumer_secret = 'test_secret'
      config.oauth_token = 'test_token'
      config.oauth_token_secret = 'test_token_secret'
    end

    twitterAccount = Twitter.new

    assert_equal([player1, player2].map { |x| x.name }, testBot.players.map { |y| y.name });
    assert_equal(twitterAccount.consumer_key, testBot.twitterAccount.consumer_key)
    assert_equal(twitterAccount.consumer_secret, testBot.twitterAccount.consumer_secret)
    assert_equal(twitterAccount.oauth_token, testBot.twitterAccount.oauth_token)
    assert_equal(twitterAccount.oauth_token_secret, testBot.twitterAccount.oauth_token_secret)
  end

  def test_get_death_metadata_handles_non_ascii_characters
    File.open(@@configFileName, 'w') { |file|
      file.puts('players=' + @@playerName + ',bug')
    }

    testBot = NethackBot.new(@@configFileName, :silent => true)
    testBot.getDeathMetadata('http://alt.org/nethack/userdata/t/thebuckley/dumplog/1252117582.nh343.txt', 'thebuckley')
  end

end
