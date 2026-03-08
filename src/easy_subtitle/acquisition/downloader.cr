require "json"

module EasySubtitle
  class SubtitleDownloader
    def initialize(@client : ApiClient, @config : Config, @log : Log)
    end

    def download(candidate : SubtitleCandidate, output_path : String) : Bool
      download(candidate, Path.new(output_path))
    end

    def download(candidate : SubtitleCandidate, output_path : Path) : Bool
      # Step 1: Request download link
      link = request_download_link(candidate.file_id)
      return false unless link

      # Step 2: Download the actual subtitle file
      download_file(link, output_path)
    end

    private def request_download_link(file_id : Int64) : String?
      body = {"file_id" => file_id}.to_json

      retries = @config.download_retry_503
      retries.times do |attempt|
        response = @client.post("/download", body)

        case response.status_code
        when 200
          json = JSON.parse(response.body)
          link = json["link"]?.try(&.as_s?)
          unless link
            @log.error "Download response missing link for file #{file_id}"
            return nil
          end
          return link
        when 503
          wait = (attempt + 1) * 2
          @log.warn "503 Service Unavailable, retrying in #{wait}s (#{attempt + 1}/#{retries})"
          sleep(wait.seconds)
        else
          @log.error "Download request failed: #{response.status_code}"
          return nil
        end
      end

      @log.error "Download failed after #{retries} retries"
      nil
    rescue ex : ApiError
      @log.error "Download request error: #{ex.message}"
      nil
    rescue ex : JSON::ParseException
      @log.error "Download response was invalid JSON: #{ex.message}"
      nil
    end

    private def download_file(url : String, output_path : Path) : Bool
      response = HTTP::Client.get(url)

      unless response.status_code == 200
        @log.error "Failed to download file: #{response.status_code}"
        return false
      end

      dir = output_path.parent
      Dir.mkdir_p(dir.to_s) unless Dir.exists?(dir.to_s)
      File.write(output_path, response.body)
      true
    rescue ex
      @log.error "Download error: #{ex.message}"
      false
    end
  end
end
