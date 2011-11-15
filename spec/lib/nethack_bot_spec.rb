require 'spec_helper'

describe NethackBot do
  let(:config_file_name) { '.nethack_bot_test' }
  let(:player) { Player.new('nbTest') }

  before(:each) {
    File.open(config_file_name, 'w') { |f|
      f.puts("players=#{player.name}")
    }
  }

  after(:each) {
    File.unlink(config_file_name) if File.exists?(config_file_name)
    File.unlink(player.gamesFile) if File.exists?(player.gamesFile)
  }

  describe '#new' do
    it 'should read the .nethack file in ~/ for configuration' do
      File.open(config_file_name, 'w') { |f|
        f.puts('players=testPlayer1,testPlayer2')
        f.puts('consumer_key=test_key')
        f.puts('consumer_secret=test_secret')
        f.puts('oauth_token=test_token')
        f.puts('oauth_token_secret=test_token_secret')
      }

      Player.should_receive(:new).with('testPlayer1')
      Player.should_receive(:new).with('testPlayer2')

      test_bot = NethackBot.new(config_file_name)

      test_bot.twitterAccount.consumer_key.should       eql 'test_key'
      test_bot.twitterAccount.consumer_secret.should    eql 'test_secret'
      test_bot.twitterAccount.oauth_token.should        eql 'test_token'
      test_bot.twitterAccount.oauth_token_secret.should eql 'test_token_secret'
    end
  end

  describe '#getDeathMetadata' do
    let(:nethack_bot) { NethackBot.new(config_file_name) }

    it 'should read the game dump at the given url and extract tweetable info' do
      nethack_bot.getDeathMetadata('http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170828.nh343.txt', 'nbTest').should == {
        :class => 'Healer',
        :level => '1',
        :killer => 'sewer rat',
      }
    end

    it 'should handle non-ASCII characters' do
      lambda {
        nethack_bot.getDeathMetadata('http://alt.org/nethack/userdata/t/thebuckley/dumplog/1252117582.nh343.txt', 'thebuckley')
      }.should_not raise_exception(ArgumentError, 'invalid byte sequence in UTF-8')
    end
  end

  describe '#run' do
    it "it should log a player's games and post them to twitter" do
      test_bot = NethackBot.new(config_file_name)

      test_bot.players.each { |p|
        p.stub(:new?) { false }
        p.stub(:newGames) { [ 'http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170828.nh343.txt' ] }
      }

      test_bot.twitterAccount.should_receive(:update).with(
        'NBTEST the Healer died. Lvl: 1. Killer: sewer rat. http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170828.nh343.txt'
      ).and_return(true)

      test_bot.run

      player.oldGames.should == [ 'http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170828.nh343.txt' ]
    end

    it 'should log games but not tweet them if silent is set' do
      test_bot = NethackBot.new(config_file_name, :silent => true)

      test_bot.players.each { |p|
        p.stub(:new?) { false }
      }

      test_bot.should_not_receive(:statusUpdate)
      test_bot.run
      test_bot.twitterAccount.should be_nil

      player.oldGames.should == [
        'http://alt.org/nethack/userdata/n/nbTest/dumplog/1252731025.nh343.txt',
        'http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170714.nh343.txt',
        'http://alt.org/nethack/userdata/n/nbTest/dumplog/1252731049.nh343.txt',
        'http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170828.nh343.txt',
      ]
    end

    it "should log a player's games but not post their updates to twitter if it's a new player" do
      test_bot = NethackBot.new(config_file_name)

      test_bot.twitterAccount.should_not_receive(:update)

      test_bot.run

      player.oldGames.should == [
        'http://alt.org/nethack/userdata/n/nbTest/dumplog/1252731025.nh343.txt',
        'http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170714.nh343.txt',
        'http://alt.org/nethack/userdata/n/nbTest/dumplog/1252731049.nh343.txt',
        'http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170828.nh343.txt',
      ]
    end
  end

  describe '#statusUpdate' do
    let(:nethack_bot) { NethackBot.new(config_file_name) }

    it 'should recognize an ascension' do
      death_metadata = { :class => 'Valkyrie', :level => 30, :killer => 'ascended' }

      nethack_bot.statusUpdate(player, 'fake_url', death_metadata).should eql 'NBTEST the Valkyrie ascended! Lvl: 30. fake_url'
    end

    it 'should recognize quitting' do
      death_metadata = { :class => 'Samurai', :level => 2, :killer => 'quit' }

      nethack_bot.statusUpdate(player, 'fake_url', death_metadata).should eql 'NBTEST the Samurai quit. Lvl: 2. fake_url'
    end

    it 'should recognize an escape' do
      death_metadata = { :class => 'Barbarian', :level => 1, :killer => 'escaped' }

      nethack_bot.statusUpdate(player, 'fake_url', death_metadata).should eql 'NBTEST the Barbarian escaped. Lvl: 1. fake_url'
    end
  end
end
