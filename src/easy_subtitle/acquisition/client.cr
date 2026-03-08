require "http/client"
require "json"

module EasySubtitle
  class ApiClient
    @last_request_at : Time = Time::UNIX_EPOCH
    @mutex : Mutex = Mutex.new
    RATE_LIMIT_MS = 500

    def initialize(@config : Config, @authenticator : Authenticator)
    end

    def get(path : String, params : Hash(String, String) = Hash(String, String).new) : HTTP::Client::Response
      throttle!
      uri = build_uri(path, params)
      headers = authenticated_headers
      HTTP::Client.get(uri, headers: headers)
    rescue ex : IO::Error | Socket::Error
      raise ApiError.new(-1, "GET #{path} failed: #{ex.message}")
    end

    def post(path : String, body : String? = nil) : HTTP::Client::Response
      throttle!
      uri = "#{@config.api_url}#{path}"
      headers = authenticated_headers
      headers["Content-Type"] = "application/json"
      HTTP::Client.post(uri, headers: headers, body: body)
    rescue ex : IO::Error | Socket::Error
      raise ApiError.new(-1, "POST #{path} failed: #{ex.message}")
    end

    def authenticated_headers : HTTP::Headers
      token = @authenticator.ensure_token!
      HTTP::Headers{
        "Api-Key"       => @config.api_key,
        "Authorization" => "Bearer #{token}",
        "User-Agent"    => "EasySubtitle v#{VERSION}",
        "Accept"        => "application/json",
      }
    end

    private def build_uri(path : String, params : Hash(String, String)) : String
      uri = "#{@config.api_url}#{path}"
      unless params.empty?
        query = params.map { |k, v| "#{URI.encode_path_segment(k)}=#{URI.encode_path_segment(v)}" }.join("&")
        uri += "?#{query}"
      end
      uri
    end

    private def throttle! : Nil
      @mutex.synchronize do
        elapsed = Time.utc - @last_request_at
        remaining = RATE_LIMIT_MS - elapsed.total_milliseconds
        if remaining > 0
          sleep(remaining.milliseconds)
        end
        @last_request_at = Time.utc
      end
    end
  end
end
