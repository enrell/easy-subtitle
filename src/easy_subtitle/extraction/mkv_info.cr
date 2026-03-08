require "json"

module EasySubtitle
  module MkvInfo
    def self.parse(json_str : String) : {subtitle_tracks: Array(SubtitleTrack), audio_tracks: Array(AudioTrack)}
      json = JSON.parse(json_str)
      tracks = json["tracks"]?.try(&.as_a?) || ([] of JSON::Any)

      subtitle_tracks = [] of SubtitleTrack
      audio_tracks = [] of AudioTrack

      tracks.each do |track|
        type = track["type"]?.try(&.as_s?) || next
        id = track["id"]?.try(&.as_i?) || next
        codec = track["codec"]?.try(&.as_s?) || ""
        props = track["properties"]?

        language = props.try(&.["language"]?.try(&.as_s?)) || "und"
        name = props.try(&.["track_name"]?.try(&.as_s?)) || ""
        default = props.try(&.["default_track"]?.try(&.as_bool?)) || false
        forced = props.try(&.["forced_track"]?.try(&.as_bool?)) || false
        codec_id = props.try(&.["codec_id"]?.try(&.as_s?)) || ""

        case type
        when "subtitles"
          subtitle_tracks << SubtitleTrack.new(
            id: id,
            language: language,
            codec: codec,
            codec_id: codec_id,
            name: name,
            default: default,
            forced: forced,
          )
        when "audio"
          audio_tracks << AudioTrack.new(
            id: id,
            language: language,
            codec: codec,
            name: name,
            default: default,
          )
        end
      end

      {subtitle_tracks: subtitle_tracks, audio_tracks: audio_tracks}
    rescue ex : JSON::ParseException
      raise Error.new("Invalid mkvmerge JSON output: #{ex.message}")
    end

    def self.identify(video_path : String) : {subtitle_tracks: Array(SubtitleTrack), audio_tracks: Array(AudioTrack)}
      result = Shell.run("mkvmerge", ["-J", video_path])
      parse(result.stdout)
    end

    def self.identify(video_path : Path) : {subtitle_tracks: Array(SubtitleTrack), audio_tracks: Array(AudioTrack)}
      identify(video_path.to_s)
    end
  end
end
