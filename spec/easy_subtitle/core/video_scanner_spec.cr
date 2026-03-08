require "../../spec_helper"

describe EasySubtitle::VideoScanner do
  describe ".video_file?" do
    it "recognizes video extensions" do
      EasySubtitle::VideoScanner.video_file?("movie.mkv").should be_true
      EasySubtitle::VideoScanner.video_file?("movie.mp4").should be_true
      EasySubtitle::VideoScanner.video_file?("movie.avi").should be_true
      EasySubtitle::VideoScanner.video_file?("movie.m4v").should be_true
    end

    it "rejects non-video extensions" do
      EasySubtitle::VideoScanner.video_file?("subtitle.srt").should be_false
      EasySubtitle::VideoScanner.video_file?("image.png").should be_false
      EasySubtitle::VideoScanner.video_file?("document.txt").should be_false
    end

    it "is case-insensitive" do
      EasySubtitle::VideoScanner.video_file?("movie.MKV").should be_true
      EasySubtitle::VideoScanner.video_file?("movie.Mp4").should be_true
    end
  end

  describe ".series_structure?" do
    it "detects SxxExx patterns" do
      Dir.mkdir_p("/tmp/easy-subtitle-test-series")
      File.write("/tmp/easy-subtitle-test-series/Show.S01E01.mkv", "")
      File.write("/tmp/easy-subtitle-test-series/Show.S01E02.mkv", "")

      EasySubtitle::VideoScanner.series_structure?("/tmp/easy-subtitle-test-series").should be_true
    ensure
      FileUtils.rm_rf("/tmp/easy-subtitle-test-series")
    end

    it "returns false for movie folders" do
      Dir.mkdir_p("/tmp/easy-subtitle-test-movie")
      File.write("/tmp/easy-subtitle-test-movie/Movie.2024.mkv", "")

      EasySubtitle::VideoScanner.series_structure?("/tmp/easy-subtitle-test-movie").should be_false
    ensure
      FileUtils.rm_rf("/tmp/easy-subtitle-test-movie")
    end
  end

  describe ".scan" do
    it "finds video files in directory" do
      Dir.mkdir_p("/tmp/easy-subtitle-test-scan")
      File.write("/tmp/easy-subtitle-test-scan/movie1.mkv", "data")
      File.write("/tmp/easy-subtitle-test-scan/movie2.mp4", "data")
      File.write("/tmp/easy-subtitle-test-scan/subtitle.srt", "data")

      config = EasySubtitle::Config.default
      videos = EasySubtitle::VideoScanner.scan("/tmp/easy-subtitle-test-scan", config)
      videos.size.should eq 2
      videos.map(&.name).should contain "movie1.mkv"
      videos.map(&.name).should contain "movie2.mp4"
    ensure
      FileUtils.rm_rf("/tmp/easy-subtitle-test-scan")
    end

    it "skips configured directories" do
      Dir.mkdir_p("/tmp/easy-subtitle-test-skip/extras")
      File.write("/tmp/easy-subtitle-test-skip/movie.mkv", "data")
      File.write("/tmp/easy-subtitle-test-skip/extras/bonus.mkv", "data")

      config = EasySubtitle::Config.default
      videos = EasySubtitle::VideoScanner.scan("/tmp/easy-subtitle-test-skip", config)
      videos.size.should eq 1
      videos[0].name.should eq "movie.mkv"
    ensure
      FileUtils.rm_rf("/tmp/easy-subtitle-test-skip")
    end

    it "raises a project error for missing paths" do
      config = EasySubtitle::Config.default

      expect_raises(EasySubtitle::Error, /Path not found/) do
        EasySubtitle::VideoScanner.scan("/tmp/easy-subtitle-does-not-exist", config)
      end
    end
  end
end
