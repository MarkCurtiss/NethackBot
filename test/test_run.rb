require 'spec_helper'

#this test actually posts to a twitter account.  for this reason, it is not included
#as part of the test suite.  it's intended to be used a sanity check to see if NethackBot
#will work on your system (necessary binaries are in the right place, it has adequate
#permissions, etc).

#note that due to twitter's de-duping algorithm you won't be able to run this script 
#repeatedly without a lengthy wait in between invocations.

describe NethackBot do
  context 'full integration test' do
    let(:config_file_name) { File.expand_path('~/.nethack_bot_test_run') }
    let(:players) { [ Player.new('nbTest'), Player.new('cultofluna') ] }

    after(:all) {
      File.unlink(config_file_name) if File.exists?(config_file_name)
      players.each { |p|
        File.unlink(p.gamesFile) if File.exists?(p.gamesFile)
      }
    }

    it 'should check a few players and post their games to the test twitter account' do
      File.open(config_file_name, 'w') { |f|
        f.puts("players=#{players.map { |p| p.name }.join(',')}")
        f.puts('consumer_key=dTYnNFT5dcmj9yXGMdtw')
        f.puts('consumer_secret=D2OmfcdMaBkKQMtzeTUmHWIXZdXbmndLPjjZY0PdA')
        f.puts('oauth_token=75188583-pNrTjuTjQE6b8TPK03WN7S0t1PoIqkPxw8zuD3DRc')
        f.puts('oauth_token_secret=nc6Y4vSRLAA2vd1G82zjmnS7iUHRgJ7YbB9IZew')
      }

      nethack_bot = NethackBot.new(config_file_name)
      nethack_bot.players.each { |p|
        p.stub(:new?) { false }
      }

      expect { nethack_bot.run }.to_not raise_error
    end
  end
end
