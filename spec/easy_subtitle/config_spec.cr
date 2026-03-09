require "../spec_helper"

describe EasySubtitle::Config do
  describe ".default" do
    it "creates config with default values" do
      config = EasySubtitle::Config.default
      config.api_url.should eq "https://api.opensubtitles.com/api/v1"
      config.languages.should eq ["en"]
      config.smart_sync.should be_true
      config.sync_backend.should eq "alass"
      config.use_movie_hash.should be_true
      config.max_search_results.should eq 10
      config.top_downloads.should eq 3
    end
  end

  describe ".load" do
    it "loads full config from YAML" do
      config = EasySubtitle::Config.load(fixture("config.yml"))
      config.api_key.should eq "test_api_key_123"
      config.username.should eq "testuser"
      config.password.should eq "testpass"
      config.languages.should eq ["en", "nl"]
      config.audio_track_languages.should eq ["en", "nl", "ja"]
      config.series_mode.should be_false
      config.smart_sync.should be_true
      config.sync_backend.should eq "alass"
    end

    it "loads minimal config with defaults" do
      config = EasySubtitle::Config.load(fixture("config_minimal.yml"))
      config.api_key.should eq "my_key"
      config.languages.should eq ["en"]
      config.smart_sync.should be_true
    end

    it "wraps invalid yaml in ConfigError" do
      path = "/tmp/easy-subtitle-invalid-config.yml"
      File.write(path, "api_key: [broken")

      expect_raises(EasySubtitle::ConfigError, /Invalid YAML/) do
        EasySubtitle::Config.load(path)
      end
    ensure
      File.delete(path) if path && File.exists?(path)
    end
  end

  describe "#validate!" do
    it "passes for valid config" do
      config = EasySubtitle::Config.default
      config.validate!
    end

    it "rejects empty languages" do
      config = EasySubtitle::Config.default
      config.languages = [] of String
      expect_raises(EasySubtitle::ConfigError, /language/) do
        config.validate!
      end
    end

    it "rejects unsupported sync_backend values" do
      config = EasySubtitle::Config.default
      config.sync_backend = "unknown"
      expect_raises(EasySubtitle::ConfigError, /sync_backend/) do
        config.validate!
      end
    end
  end

  describe "#to_yaml_string" do
    it "round-trips through YAML" do
      original = EasySubtitle::Config.default
      yaml = original.to_yaml_string
      loaded = EasySubtitle::Config.from_yaml(yaml)
      loaded.api_url.should eq original.api_url
      loaded.languages.should eq original.languages
      loaded.smart_sync.should eq original.smart_sync
    end
  end
end
