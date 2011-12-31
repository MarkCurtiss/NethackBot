class Game
  attr_accessor :url

  def initialize(url, id=nil)
    @url = url
    @id = id
    @game_contents = nil
  end

  def ==(other_game)
    @url.eql?(other_game.url) || self.id.eql?(other_game.id)
  end

  def eql?(other_game)
    self == other_game && self.class == other_game.class
  end

  def id
    return @id unless @id.nil?
    @id = Digest::MD5.hexdigest(self.contents)
    return @id
  end

  def hash
    return @hash unless @hash.nil?
    @hash = self.contents.hash
    return @hash
  end

  def death_metadata
    death_text = self.contents
    death_metadata = Hash.new

    death_text.match(/^(\w+), (neutral|chaotic|lawful) (female|male) \w+ (\w+)/)
    death_metadata[:player] = $1 if $1
    death_metadata[:class] = $4 if $4

    death_text.match(/^You were level (.*) with a maximum of \d+ hit points/)
    death_metadata[:level] = $1 if $1

    death_text.match(/^Killer: (.*)/)
    death_metadata[:killer] = $1 if $1

    return death_metadata
  end

  def contents
    return @game_contents unless @game_contents.nil?
    command_string = '/usr/bin/curl --silent ' + @url
    @game_contents = `#{command_string}`.encode('ASCII', :invalid => :replace)
  end
end
