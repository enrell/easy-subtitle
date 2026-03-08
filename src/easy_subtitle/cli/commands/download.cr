module EasySubtitle
  module CLI
    class DownloadCommand
      def initialize(@config : Config, @log : Log)
      end

      def run(args : Array(String)) : Nil
        languages = @config.languages.dup

        parser = OptionParser.new do |p|
          p.banner = "Usage: easy-subtitle download [OPTIONS] PATH"
          p.on("-l LANGS", "--languages LANGS", "Languages (comma-separated)") do |l|
            languages = l.split(",").map(&.strip)
          end
        end
        parser.parse(args)

        path = args.last?
        unless path
          STDERR.puts parser
          return
        end

        videos = VideoScanner.scan(path, @config)
        if videos.empty?
          @log.warn "No video files found in: #{path}"
          return
        end

        auth = Authenticator.new(@config)
        client = ApiClient.new(@config, auth)
        search = SubtitleSearch.new(client, @config, @log)
        downloader = SubtitleDownloader.new(client, @config, @log)
        series_mode = VideoScanner.detect_mode(path, @config) == :series

        total_downloaded = 0
        videos.each do |video|
          begin
            if @config.use_movie_hash
              video.compute_hash!
            end

            languages.each do |lang|
              candidates = search.search(video, lang, series_mode)
              if candidates.empty?
                @log.warn "No subtitles found for #{video.name} [#{lang}]"
                next
              end

              count = 0
              candidates.first(@config.top_downloads).each do |candidate|
                output_dir = video.directory
                output_name = "#{video.stem}.#{lang}.#{candidate.file_id}.srt"
                output_path = output_dir / output_name

                if downloader.download(candidate, output_path)
                  @log.success "Downloaded: #{output_name}"
                  count += 1
                end
              end
              total_downloaded += count
            end
          rescue ex : Exception
            @log.error "Failed to process #{video.name}: #{ex.message}"
          end
        end

        @log.success "Downloaded #{total_downloaded} subtitle(s)"
      end
    end
  end
end
