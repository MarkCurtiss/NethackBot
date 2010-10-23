class TwitterAccount
  attr_accessor :userName, :password

  def initialize(userName, password)
    @userName = userName
    @password = password
  end

  def updateCommand(status)
    "/usr/bin/curl -u #{userName}:#{password} -d status=\"#{status}\" http://twitter.com/statuses/update.json"
  end

  def update(status)
    raise ArgumentError if status.length > 140
    postToTwitter(status).include?(self.userName)
  end

  private
  def postToTwitter(status)
    
    commandString = self.updateCommand(status)
    `#{commandString}`
  end
end
