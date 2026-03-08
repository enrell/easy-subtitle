module EasySubtitle
  module VideoScanner
    VIDEO_EXTENSIONS = {".mkv", ".mp4", ".avi", ".m4v", ".mov", ".wmv"}
    SERIES_PATTERN   = /[Ss]\d{2}[Ee]\d{2}/

    def self.scan(path : Path, config : Config) : Array(VideoFile)
      scan(path.to_s, config)
    end

    def self.scan(path : String, config : Config) : Array(VideoFile)
      results = [] of VideoFile
      root = Path.new(path)

      unless File.exists?(path)
        raise Error.new("Path not found: #{path}")
      end

      if File.file?(path)
        if video_file?(path)
          results << VideoFile.from_path(path)
        end
        return results
      end

      walk(root, config.skip_dirs) do |file_path|
        results << VideoFile.from_path(file_path)
      end

      results.sort_by!(&.name)
      results
    end

    def self.video_file?(path : String) : Bool
      VIDEO_EXTENSIONS.includes?(File.extname(path).downcase)
    end

    def self.video_file?(path : Path) : Bool
      video_file?(path.to_s)
    end

    def self.series_structure?(path : String) : Bool
      dir = File.directory?(path) ? path : File.dirname(path)
      Dir.children(dir).any? { |name| SERIES_PATTERN.matches?(name) }
    rescue
      false
    end

    def self.detect_mode(path : String, config : Config) : Symbol
      if config.series_mode
        :series
      elsif series_structure?(path)
        :series
      else
        :movie
      end
    end

    private def self.walk(dir : Path, skip_dirs : Array(String), &block : Path ->) : Nil
      Dir.each_child(dir.to_s) do |name|
        full_path = dir / name
        if File.directory?(full_path.to_s)
          next if skip_dirs.any? { |skip| name.downcase == skip.downcase }
          walk(full_path, skip_dirs, &block)
        elsif video_file?(full_path)
          yield full_path
        end
      end
    rescue ex : File::AccessDeniedError | File::NotFoundError
      # Skip directories that disappeared or can't be read.
    end
  end
end
