#!/usr/bin/env ruby

require 'test/unit'
require 'twitter_account.rb'

class TwitterAccountTest < Test::Unit::TestCase
  def test_update_comand
    testTwitterAccount = TwitterAccount.new('sswtestnb', 'testPassword')
    assert_equal('/usr/bin/curl -u sswtestnb:testPassword -d status="testStatus" http://twitter.com/statuses/update.json',
                 testTwitterAccount.updateCommand('testStatus'));
  end

  def test_update_refuses_updates_longer_than_twitters_post_limit
    testTwitterAccount = TwitterAccount.new('sswtestnb', 'testPassword')
    assert_raise ArgumentError do testTwitterAccount.update('z' * 141) end
  end

  def test_update_returns_false_unless_json_returned_contains_username
    testTwitterAccount = TwitterAccount.new('sswtestnb', 'testPassword')
    #postToTwitter is called by update
    def testTwitterAccount.postToTwitter(status)
      return <<JSON_STRING
 % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed

  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
JSON_STRING
    end

    assert_equal(false, testTwitterAccount.update('test status update'))

    def testTwitterAccount.postToTwitter(status)
      return <<JSON_STRING
{"in_reply_to_user_id":null,"in_reply_to_screen_name":null,"user":{"description":"","utc_offset":-28800,"friends_count":0,"profile_sidebar_fill_color":"e0ff92","time_zone":"Pacific Time (US & Canada)","created_at":"Mon May 04 02:59:37 +0000 2009","profile_image_url":null,"favourites_count":0,"profile_sidebar_border_color":"87bc44","statuses_count":179,"url":null,"screen_name":"sswtestnb","name":"sswtestnb","protected":false,"profile_text_color":"000000","profile_background_image_url":"http:\/\/s.twimg.com\/a\/1250203207\/images\/themes\/theme1\/bg.gif","following":false,"verified":false,"profile_link_color":"0000ff","profile_background_tile":false,"location":"","id":666,"notifications":false,"profile_background_color":"9ae4e8","followers_count":15},"created_at":"Tue Sep 08 04:04:07 +0000 2009","truncated":false,"in_reply_to_status_id":null,"text":"test status update","id":383  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed

100  1130  100  1130    0     0   3000      0 --:--:-- --:--:-- --:--:--  3000
100  1130  100  1130    0     0   2999      0 --:--:-- --:--:-- --:--:--     0
3538787,"favorited":false,"source":"<a href=\"http:\/\/apiwiki.twitter.com\/\" rel=\"nofollow\">API<\/a>"}
JSON_STRING
    end

    assert_equal(true, testTwitterAccount.update('test status update'))
  end
end
