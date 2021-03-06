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

  describe '#run' do
    it "it should log a player's games and post them to twitter" do
      test_bot = NethackBot.new(config_file_name)

      test_bot.players.each { |p|
        p.stub(:new?) { false }
        p.stub(:newGames) { [ Game.new('http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170828.nh343.txt') ] }
      }

      test_bot.twitterAccount.should_receive(:update).with(
        'nbTest the Healer died. Lvl: 1. Killer: sewer rat. http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170828.nh343.txt'
      ).and_return(true)

      test_bot.run

      player.oldGames.should == [ Game.new('http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170828.nh343.txt') ]
    end

    it 'should not log the game or post it to twitter if death metadata is incomplete' do
      test_bot = NethackBot.new(config_file_name)

      test_bot.players.each { |p|
        p.stub(:new?) { false }
        p.stub(:newGames) {
          game = Game.new('fake_url')
          game.stub(:death_metadata) { {:class => 'Healer', :level => 1} }
          [ game ]
        }
      }
      test_bot.twitterAccount.should_not_receive(:update)

      test_bot.run

      player.oldGames.should == []
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
      ].map { |url| Game.new(url) }
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
      ].map { |url| Game.new(url) }
    end

  end

  describe '#statusUpdate' do
    let(:nethack_bot) { NethackBot.new(config_file_name) }

    it 'should use the player name from the actual dumplog to preserve casing' do
      death_metadata = { :player => 'mIxEd CaSe', :class => 'Knight', :level => 1, :killer => 'slipped while mounting a saddled pony' }

      nethack_bot.statusUpdate(player, 'fake_url', death_metadata).should eql 'mIxEd CaSe the Knight died. Lvl: 1. Killer: slipped while mounting a saddled pony. fake_url'
    end

    it 'should recognize an ascension' do
      death_metadata = { :player => 'nbTest', :class => 'Valkyrie', :level => 30, :killer => 'ascended' }

      nethack_bot.statusUpdate(player, 'fake_url', death_metadata).should eql 'nbTest the Valkyrie ascended! Lvl: 30. fake_url'
    end

    it 'should recognize quitting' do
      death_metadata = { :player => 'nbTest', :class => 'Samurai', :level => 2, :killer => 'quit' }

      nethack_bot.statusUpdate(player, 'fake_url', death_metadata).should eql 'nbTest the Samurai quit. Lvl: 2. fake_url'
    end

    it 'should recognize an escape' do
      death_metadata = { :player => 'nbTest', :class => 'Barbarian', :level => 1, :killer => 'escaped' }

      nethack_bot.statusUpdate(player, 'fake_url', death_metadata).should eql 'nbTest the Barbarian escaped. Lvl: 1. fake_url'
    end
  end
end
