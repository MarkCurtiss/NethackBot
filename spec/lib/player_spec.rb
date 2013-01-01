require 'spec_helper'

#Most tests in this spec use the player nbTest.  This is because nbTest has a few dummy games setup
#on alt.org specifically for testing (http://alt.org/nethack/dumplogs.php?player=nbTest).  If you change the playername,
#the tests will fail unless the new name is also a player on alt.org

describe Player do
  let(:test_player) { Player.new('nbTest') }
  after(:each) {
    File.unlink(test_player.gamesFile) if File.exists?(test_player.gamesFile)
  }

  describe '#url' do
    it "returns the URL where that player's games can be found" do
      test_player.url.should eql 'http://alt.org/nethack/dumplogs.php?player=nbTest',
    end
  end

  describe '#gamesFile' do
    it "returns the filename where the players games are stored on disk" do
      test_player.gamesFile.should eql Dir.pwd + '/test/games/nbTest.games'
    end
  end

  describe '#newGames' do
    it 'should return a list of game objects' do
      test_player.newGames.should == [
        'http://alt.org/nethack/userdata/n/nbTest/dumplog/1252731025.nh343.txt',
        'http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170714.nh343.txt',
        'http://alt.org/nethack/userdata/n/nbTest/dumplog/1252731049.nh343.txt',
        'http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170828.nh343.txt',
      ].map { |url| Game.new(url) }
    end

    it "should exclude games which we've already logged in the player's gamesFile" do
      games = test_player.newGames

      test_player.serializeGame(games[1])
      test_player.newGames.size.should == 3

      test_player.serializeGame(games[0])
      test_player.newGames.size.should == 2
    end

    it 'should handle players with a large number of games without dying due to an edge case in open-uri' do
      prolific_player = Player.new('graa')
      lambda {
        prolific_player.newGames
      }.should_not raise_error
    end
  end

  describe '#serializeGame' do
    it "should write the url for the game to the player's gamesFile" do
      game = test_player.newGames[1]
      test_player.serializeGame(game)

      games_on_disk = File.open(test_player.gamesFile).gets
      games_on_disk.should eql "http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170714.nh343.txt\n"
    end
  end

  describe '#oldGames' do
    it 'should return a list of games which have already been logged for this player' do
      game = test_player.newGames.first
      test_player.serializeGame(game)

      test_player.oldGames.should == [ game ]
    end
  end

  describe '#new?' do
    it "should indicate if we've ever seen this player before (i.e. we've logged some of their games)" do
      test_player.new?.should be_true

      games = test_player.newGames
      test_player.new?.should be_true

      test_player.serializeGame(games.first)
      test_player.new?.should be_false
    end
  end
end
