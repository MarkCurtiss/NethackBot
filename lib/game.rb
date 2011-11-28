class Game
  attr_accessor :url

  def initialize(url)
    @url = url
  end

  def ==(other_game)
    @url.eql?(other_game.url)
  end

  def eql?(other_game)
    self == other_game && self.class == other_game.class
  end

  def hash
    @url.hash
  end

  def death_metadata
    death_text = self.contents
    death_metadata = Hash.new

    death_text =~ /^\w+, (neutral|chaotic|lawful) (female|male) \w+ (\w+)/
    death_metadata[:class] = $3 if $3

    death_text =~ /^You were level (.*) with a maximum of \d+ hit points/
    death_metadata[:level] = $1 if $1

    death_text =~ /^Killer: (.*)/
    death_metadata[:killer] = $1 if $1

    return death_metadata
  end

  protected
  def contents
     command_string = '/usr/bin/curl --silent ' + @url
     return `#{command_string}`.encode('ASCII', :invalid => :replace)
  end
end
