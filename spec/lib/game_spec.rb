require 'spec_helper'

describe Game do
  let(:game) { Game.new('http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170828.nh343.txt') }

  describe '#url' do
    it 'should return the url for this game' do
      game.url.should eql 'http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170828.nh343.txt'
    end
  end

  context 'equality testing' do
    let(:same_game) { Game.new('http://alt.org/nethack/userdata/n/nbTest/dumplog/1263170828.nh343.txt') }
    let(:different_game) { Game.new('http://www.achewood.com') }

    describe '#==' do
      it 'should consider two games equal if they have the same url' do
        game.should == same_game
        game.should_not == different_game
      end

      it 'should consider two games equal if they have different urls but the same contents' do
        game.stub(:contents)           { '20 Minutes / 40 Years' }
        different_game.stub(:contents) { '20 Minutes / 40 Years' }

        game.should == different_game
        game.should == same_game
      end

      it 'should only compare contents if urls are different (for performance)' do
        num_times_called = 0

        same_game.stub(:contents) { num_times_called += 1; '' }
        same_game == game
        num_times_called.should == 0

        same_game == different_game
        num_times_called.should == 1
      end
    end

    describe '#eql?' do
      it 'should be eql if games have the same url' do
        game.eql?(same_game).should be_true
        game.eql?(different_game).should_not be_true
      end

      it 'should be eql if games have the same url and contents' do
        game.stub(:contents)      { 'Slow Riot for New Zero Kanada' }
        same_game.stub(:contents) { 'Slow Riot for New Zero Kanada' }

        game.eql?(same_game).should be_true
      end
    end

    describe '#hash' do
      it 'should hash two games to the same value if they have the same contents, regardless of url' do
        game.stub(:contents) { '20 Minutes / 40 Years' }
        same_game.stub(:contents) { 'Wavering Radiant' }
        different_game.stub(:contents) { '20 Minutes / 40 Years' }

        game.hash.should == different_game.hash
        game.hash.should_not == same_game.hash
      end
    end
  end

  describe '#death_metadata' do
    it 'should return a hash with information about how the player died' do
      game.death_metadata.should == {
        :player => 'nbTest',
        :class => 'Healer',
        :level => '1',
        :killer => 'sewer rat',
      }
    end

    it "should handle when a piece of metadata is missing" do
      game.stub(:contents) { <<TEXT
nbTest, neutral female gnomish Healer
You were level 1 with a maximum of 12 hit points when you died.
TEXT
      }
      game.death_metadata.should == {
        :player => 'nbTest',
        :class => 'Healer',
        :level => '1',
      }

      game.stub(:contents) { <<TEXT
nbTest, neutral female gnomish Healer
Killer: sewer rat
TEXT
      }
      game.death_metadata.should == {
        :player => 'nbTest',
        :class => 'Healer',
        :killer => 'sewer rat',
      }

      game.stub(:contents) { <<TEXT
Killer: sewer rat
You were level 1 with a maximum of 12 hit points when you quit.
TEXT
      }
      game.death_metadata.should == {
        :killer => 'sewer rat',
        :level => '1',
      }
    end

    it 'should handle non-ASCII characters' do
      expect {
        Game.new('http://alt.org/nethack/userdata/t/thebuckley/dumplog/1252117582.nh343.txt').death_metadata('thebuckley')
      }.to_not raise_exception(ArgumentError, 'invalid byte sequence in UTF-8')
    end
  end
end
