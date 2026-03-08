module EasySubtitle
  class Remuxer
    def initialize(@config : Config, @log : Log)
    end

    def remux(video : VideoFile) : Bool
      unless video.extension.downcase == ".mkv"
        return false
      end

      info = MkvInfo.identify(video.path)
      audio_tracks = info[:audio_tracks]
      subtitle_tracks = info[:subtitle_tracks]

      # Determine which tracks to keep
      keep_audio = select_audio_tracks(audio_tracks)
      keep_subs = select_subtitle_tracks(subtitle_tracks)

      # If keeping everything, no need to remux
      if keep_audio.size == audio_tracks.size && keep_subs.size == subtitle_tracks.size
        @log.debug "No tracks to remove from #{video.name}"
        return false
      end

      # Build mkvmerge arguments
      temp_path = video.directory / ".temp_#{video.name}"
      args = build_remux_args(video.path, temp_path, keep_audio, keep_subs)

      begin
        Spinner.run("Remuxing #{video.name}") do
          Shell.run("mkvmerge", args)
        end

        # Replace original with remuxed
        File.rename(temp_path.to_s, video.path.to_s)
        @log.success "Remuxed #{video.name}: kept #{keep_audio.size} audio, #{keep_subs.size} subtitle tracks"
        true
      rescue ex : Exception
        File.delete(temp_path.to_s) if File.exists?(temp_path.to_s)
        @log.error "Remux failed: #{ex.message}"
        false
      end
    end

    private def select_audio_tracks(tracks : Array(AudioTrack)) : Array(AudioTrack)
      return tracks if @config.audio_track_languages.includes?("ALL")

      wanted = @config.audio_track_languages
      tracks.select do |track|
        lang2 = track.language_2
        lang2 == "und" || wanted.any? { |w| Language.equivalent?(w, lang2) }
      end
    end

    private def select_subtitle_tracks(tracks : Array(SubtitleTrack)) : Array(SubtitleTrack)
      return tracks if @config.preserve_unwanted_subtitles

      tracks.select do |track|
        if track.forced && @config.preserve_forced_subtitles
          true
        else
          lang2 = track.language_2
          @config.languages.any? { |l| Language.equivalent?(l, lang2) }
        end
      end
    end

    private def build_remux_args(input : Path, output : Path, keep_audio : Array(AudioTrack), keep_subs : Array(SubtitleTrack)) : Array(String)
      args = ["-o", output.to_s]

      if keep_audio.empty?
        args << "--no-audio"
      else
        audio_ids = keep_audio.map(&.id.to_s).join(",")
        args += ["--audio-tracks", audio_ids]
      end

      if keep_subs.empty?
        args << "--no-subtitles"
      else
        sub_ids = keep_subs.map(&.id.to_s).join(",")
        args += ["--subtitle-tracks", sub_ids]
      end

      args << input.to_s
      args
    end
  end
end
