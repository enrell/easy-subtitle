require "../../spec_helper"
require "webmock"

describe EasySubtitle::Authenticator do
  before_each { WebMock.reset }
  after_each { WebMock.reset }

  it "logs in and returns token" do
    config = EasySubtitle::Config.default
    config.api_key = "test_key"
    config.username = "testuser"
    config.password = "testpass"

    WebMock.stub(:post, "https://api.opensubtitles.com/api/v1/login")
      .to_return(body: %({"token": "jwt_token_abc"}))

    auth = EasySubtitle::Authenticator.new(config)
    token = auth.login!
    token.should eq "jwt_token_abc"
  end

  it "raises on failed login" do
    config = EasySubtitle::Config.default
    config.api_key = "bad_key"

    WebMock.stub(:post, "https://api.opensubtitles.com/api/v1/login")
      .to_return(status: 401, body: %({"message": "Unauthorized"}))

    auth = EasySubtitle::Authenticator.new(config)
    expect_raises(EasySubtitle::ApiError) do
      auth.login!
    end
  end

  it "raises when the login response is missing a token" do
    config = EasySubtitle::Config.default
    config.api_key = "test_key"
    config.username = "testuser"
    config.password = "testpass"

    WebMock.stub(:post, "https://api.opensubtitles.com/api/v1/login")
      .to_return(body: %({"ok": true}))

    auth = EasySubtitle::Authenticator.new(config)
    expect_raises(EasySubtitle::ApiError, /missing token/) do
      auth.login!
    end
  end
end
