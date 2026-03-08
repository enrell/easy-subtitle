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
      language_counts = subtitle_tracks.each_with_object(Hash(String, Int32).new(0)) do |track, counts|
        next unless track.extractable?
        counts[track.language_2] += 1
      end

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
        output_name = build_output_name(video, lang2, track.id, ext, language_counts[lang2] > 1)
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
        rescue ex : Exception
          @log.error "Failed to extract track #{track.id}: #{ex.message}"
        end
      end

      extracted
    rescue ex : Exception
      @log.error "Failed to inspect #{video.name}: #{ex.message}"
      [] of Path
    end

    private def build_output_name(video : VideoFile, lang2 : String, track_id : Int32, extension : String, duplicate_language : Bool) : String
      if duplicate_language
        "#{video.stem}.#{lang2}.track#{track_id}#{extension}"
      else
        "#{video.stem}.#{lang2}#{extension}"
      end
    end
  end
end
