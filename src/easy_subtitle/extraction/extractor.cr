module EasySubtitle
  class Extractor
    def initialize(@config : Config, @log : Log)
    end

    def extract(video : VideoFile) : Array(Path)
      unless video.extension.downcase == ".mkv"
        @log.info "Skipping non-MKV: #{video.name}"
        return [] of Path
      end

      info = Spinner.run("Identifying tracks in #{video.name}") do
        MkvInfo.identify(video.path)
      end
      subtitle_tracks = info[:subtitle_tracks]

      if subtitle_tracks.empty?
        @log.info "No subtitle tracks in #{video.name}"
        return [] of Path
      end

      extracted = [] of Path

      subtitle_tracks.each do |track|
        next unless track.extractable?

        if track.forced && !@config.preserve_forced_subtitles
          @log.debug "Skipping forced track #{track.id} (#{track.language})"
          next
        end

        lang2 = track.language_2
        unless @config.preserve_unwanted_subtitles
          unless @config.languages.any? { |l| Language.equivalent?(l, lang2) }
            @log.debug "Skipping unwanted language: #{track.language}"
            next
          end
        end

        ext = track.ass? ? ".ass" : ".srt"
        output_name = "#{video.stem}.#{lang2}#{ext}"
        output_path = video.directory / output_name

        if File.exists?(output_path) && !@config.resync_mode
          @log.debug "Already extracted: #{output_name}"
          extracted << output_path
          next
        end

        begin
          Spinner.run("Extracting track #{track.id} (#{track.language})") do
            Shell.run("mkvextract", ["tracks", video.path.to_s, "#{track.id}:#{output_path}"])
          end
          @log.success "Extracted: #{output_name}"
          extracted << output_path
        rescue ex : ExternalToolError
          @log.error "Failed to extract track #{track.id}: #{ex.message}"
        end
      end

      extracted
    end
  end
end
