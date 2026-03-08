module EasySubtitle
  module CLI
    class SyncCommand
      def initialize(@config : Config, @log : Log)
      end

      def run(args : Array(String)) : Nil
        languages = @config.languages.dup

        parser = OptionParser.new do |p|
          p.banner = "Usage: easy-subtitle sync [OPTIONS] PATH"
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

        syncer = Syncer.new(@config, @log)
        accepted = 0
        total = 0

        videos.each do |video|
          languages.each do |lang|
            begin
              candidates = find_candidates(video, lang)
              next if candidates.empty?
              total += 1

              result = syncer.sync(video, candidates, lang)
              accepted += 1 if result && result.accepted?
            rescue ex : Exception
              @log.error "Failed to sync #{video.name} [#{lang}]: #{ex.message}"
            end
          end
        end

        @log.success "Sync complete: #{accepted}/#{total} accepted"
      end

      private def find_candidates(video : VideoFile, lang : String) : Array(Path)
        dir = video.directory
        pattern = "#{video.stem}.#{lang}."
        candidates = [] of Path

        Dir.each_child(dir.to_s) do |name|
          if name.starts_with?(pattern) && name.ends_with?(".srt")
            candidates << dir / name
          end
        end

        candidates
      rescue ex : File::Error
        @log.error "Failed to read #{dir}: #{ex.message}"
        [] of Path
      end
    end
  end
end
