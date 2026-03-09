module EasySubtitle
  module CLI
    module SkipCheck
      private def extracted_from_video?(video : VideoFile, lang : String) : Bool
        return false if @extracted_finals.empty?

        final = SubtitleFiles.final_path(video, lang)
        @extracted_finals.includes?(final.to_s)
      end

      private def final_subtitle_present?(video : VideoFile, lang : String) : Bool
        return false if @config.resync_mode

        File.exists?(SubtitleFiles.final_path(video, lang).to_s)
      end
    end
  end
end
