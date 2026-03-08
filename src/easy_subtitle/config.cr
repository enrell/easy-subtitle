require "yaml"

module EasySubtitle
  class Config
    include YAML::Serializable

    @[YAML::Field(key: "api_key")]
    property api_key : String = ""

    @[YAML::Field(key: "username")]
    property username : String = ""

    @[YAML::Field(key: "password")]
    property password : String = ""

    @[YAML::Field(key: "api_url")]
    property api_url : String = "https://api.opensubtitles.com/api/v1"

    @[YAML::Field(key: "languages")]
    property languages : Array(String) = ["en"]

    @[YAML::Field(key: "audio_track_languages")]
    property audio_track_languages : Array(String) = ["en", "ja"]

    @[YAML::Field(key: "accept_offset_threshold")]
    property accept_offset_threshold : Float64 = 0.101

    @[YAML::Field(key: "reject_offset_threshold")]
    property reject_offset_threshold : Float64 = 2.5

    @[YAML::Field(key: "series_mode")]
    property series_mode : Bool = false

    @[YAML::Field(key: "smart_sync")]
    property smart_sync : Bool = true

    @[YAML::Field(key: "use_movie_hash")]
    property use_movie_hash : Bool = true

    @[YAML::Field(key: "last_resort_search")]
    property last_resort_search : Bool = false

    @[YAML::Field(key: "preserve_forced_subtitles")]
    property preserve_forced_subtitles : Bool = false

    @[YAML::Field(key: "preserve_unwanted_subtitles")]
    property preserve_unwanted_subtitles : Bool = false

    @[YAML::Field(key: "resync_mode")]
    property resync_mode : Bool = false

    @[YAML::Field(key: "max_search_results")]
    property max_search_results : Int32 = 10

    @[YAML::Field(key: "top_downloads")]
    property top_downloads : Int32 = 3

    @[YAML::Field(key: "download_retry_503")]
    property download_retry_503 : Int32 = 6

    @[YAML::Field(key: "skip_dirs")]
    property skip_dirs : Array(String) = DEFAULT_SKIP_DIRS

    @[YAML::Field(key: "unwanted_terms")]
    property unwanted_terms : Array(String) = DEFAULT_UNWANTED_TERMS

    @[YAML::Field(key: "extras_folder_name")]
    property extras_folder_name : String = "extras"

    @[YAML::Field(key: "delete_extra_videos")]
    property delete_extra_videos : Bool = false

    DEFAULT_SKIP_DIRS = [
      "new folder", "extra", "extra's", "extras", "featurettes", "bonus",
      "bonusmaterial", "bonus_material", "behindthescenes", "behind_the_scenes",
      "deletedscenes", "deleted_scenes", "interviews", "makingof", "making_of",
      "scenes", "trailer", "trailers", "sample", "samples", "other", "misc",
      "specials", "special_features", "documentary", "docs", "docu", "promo",
      "promos", "bloopers", "outtakes", "moved_subtitles",
    ]

    DEFAULT_UNWANTED_TERMS = [
      "sample", "cam", "ts", "workprint", "unrated", "uncut", "720p", "1080p",
      "2160p", "480p", "4k", "uhd", "imax", "web", "webrip", "web-dl", "bluray",
      "brrip", "bdrip", "dvdrip", "hdrip", "hdtv", "remux", "x264", "x265",
      "h.264", "h.265", "hevc", "avc", "hdr", "hdr10", "hdr10+", "dv",
      "dolby.vision", "sdr", "10bit", "8bit", "ddp", "dd+", "dts", "aac", "ac3",
      "eac3", "truehd", "atmos", "flac", "5.1", "7.1", "2.0", "yts", "yts.mx",
      "yify", "rarbg", "fgt", "galaxyrg", "evo", "sparks", "drones", "amiable",
      "tigole", "fitgirl", "xvid", "mp3",
    ]

    def initialize
    end

    def self.default : Config
      Config.new
    end

    def self.load(path : String) : Config
      content = File.read(path)
      config = Config.from_yaml(content)
      config.validate!
      config
    rescue ex : File::Error
      raise ConfigError.new("Failed to read config #{path}: #{ex.message}")
    rescue ex : YAML::ParseException
      raise ConfigError.new("Invalid YAML in #{path}: #{ex.message}")
    end

    def self.load(path : Path) : Config
      load(path.to_s)
    end

    def validate! : Nil
      if accept_offset_threshold < 0
        raise ConfigError.new("accept_offset_threshold must be >= 0")
      end
      if reject_offset_threshold < 0
        raise ConfigError.new("reject_offset_threshold must be >= 0")
      end
      if accept_offset_threshold >= reject_offset_threshold
        raise ConfigError.new("accept_offset_threshold must be < reject_offset_threshold")
      end
      if max_search_results < 1
        raise ConfigError.new("max_search_results must be >= 1")
      end
      if top_downloads < 1
        raise ConfigError.new("top_downloads must be >= 1")
      end
      if languages.empty?
        raise ConfigError.new("at least one language must be configured")
      end
    end

    def to_yaml_string : String
      to_yaml
    end

    def self.default_path : Path
      Path.home / ".config" / "easy-subtitle" / "config.yml"
    end

    def self.token_path : Path
      Path.home / ".config" / "easy-subtitle" / "token"
    end
  end
end
