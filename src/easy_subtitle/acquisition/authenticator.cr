require "http/client"
require "json"

module EasySubtitle
  class Authenticator
    getter token : String?
    @token_path : Path

    def initialize(@config : Config)
      @token_path = Config.token_path
    end

    def ensure_token! : String
      if cached = load_cached_token
        @token = cached
        return cached
      end

      login!
    end

    def login! : String
      body = {
        "username" => @config.username,
        "password" => @config.password,
      }.to_json

      headers = HTTP::Headers{
        "Content-Type" => "application/json",
        "Api-Key"      => @config.api_key,
        "User-Agent"   => "EasySubtitle v#{VERSION}",
      }

      response = HTTP::Client.post("#{@config.api_url}/login", headers: headers, body: body)

      unless response.status_code == 200
        raise ApiError.new(response.status_code, response.body)
      end

      json = JSON.parse(response.body)
      jwt = json["token"]?.try(&.as_s?) || raise ApiError.new(200, "Login response missing token")

      save_token(jwt)
      @token = jwt
      jwt
    rescue ex : JSON::ParseException
      raise ApiError.new(200, "Invalid login response: #{ex.message}")
    rescue ex : IO::Error | Socket::Error
      raise ApiError.new(-1, "Login request failed: #{ex.message}")
    end

    def load_cached_token : String?
      return nil unless File.exists?(@token_path)
      token = File.read(@token_path).strip
      return nil if token.empty?
      token
    end

    def save_token(token : String) : Nil
      dir = @token_path.parent
      Dir.mkdir_p(dir.to_s) unless Dir.exists?(dir.to_s)
      File.write(@token_path, token)
    end

    def clear_token! : Nil
      File.delete(@token_path) if File.exists?(@token_path)
      @token = nil
    end
  end
end
