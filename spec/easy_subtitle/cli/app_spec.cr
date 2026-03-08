require "../../spec_helper"

class AlwaysFailingRunner < EasySubtitle::SyncBackend
  def initialize(log : EasySubtitle::Log)
    super(log)
  end

  def name : String
    "always-failing"
  end

  def binary_names : Array(String)
    ["always-failing"]
  end

  def install_help : String
    "n/a"
  end

  def sync(video_path : Path, sub_in : Path, sub_out : Path) : EasySubtitle::ShellResult
    EasySubtitle::ShellResult.new(stdout: "", stderr: "no match", exit_code: 1)
  end
end

class CopyingRunnerForSyncer < EasySubtitle::SyncBackend
  def initialize(log : EasySubtitle::Log)
    super(log)
  end

  def name : String
    "copying"
  end

  def binary_names : Array(String)
    ["copying"]
  end

  def install_help : String
    "n/a"
  end

  def sync(video_path : Path, sub_in : Path, sub_out : Path) : EasySubtitle::ShellResult
    File.copy(sub_in.to_s, sub_out.to_s)
    EasySubtitle::ShellResult.new(stdout: "", stderr: "", exit_code: 0)
  end
end

describe EasySubtitle::CLI::App do
  it "can be instantiated" do
    app = EasySubtitle::CLI::App.new
    app.should_not be_nil
  end

  it "moves failed numbered subtitle candidates into the centralized cache" do
    dir = Path.new("/tmp/easy-subtitle-sync-cleanup")
    Dir.mkdir_p(dir.to_s)

    video_path = dir / "movie.mkv"
    c1 = dir / "movie.en.d100.f1.srt"
    c2 = dir / "movie.en.d200.f2.srt"

    File.write(video_path.to_s, "video")
    File.write(c1.to_s, "1\n00:00:01,000 --> 00:00:02,000\nhi\n")
    File.write(c2.to_s, "1\n00:00:01,000 --> 00:00:02,000\nhi\n")

    log = EasySubtitle::Log.new(colorize: false, io: IO::Memory.new)
    syncer = EasySubtitle::Syncer.new(EasySubtitle::Config.default, log, AlwaysFailingRunner.new(log))
    video = EasySubtitle::VideoFile.from_path(video_path)

    result = syncer.sync(video, [c1, c2], "en")
    result.should_not be_nil
    result.not_nil!.status.failed?.should be_true
    File.exists?(c1.to_s).should be_false
    File.exists?(c2.to_s).should be_false
    EasySubtitle::SubtitleCache.cached_candidate_file_ids(video, "en").should eq Set{1_i64, 2_i64}
  ensure
    EasySubtitle::SubtitleCache.clear(video, "en") if video
    FileUtils.rm_rf(dir.to_s) if dir
  end

  it "does not report success when the final subtitle disappears after cleanup" do
    dir = Path.new("/tmp/easy-subtitle-final-guard")
    Dir.mkdir_p(dir.to_s)

    video_path = dir / "movie.mkv"
    final_candidate = dir / "movie.en.srt"

    File.write(video_path.to_s, "video")
    File.write(final_candidate.to_s, "1\n00:00:01,000 --> 00:00:02,000\nhi\n")

    log = EasySubtitle::Log.new(colorize: false, io: IO::Memory.new)
    syncer = EasySubtitle::Syncer.new(EasySubtitle::Config.default, log, CopyingRunnerForSyncer.new(log))
    video = EasySubtitle::VideoFile.from_path(video_path)

    result = syncer.sync(video, [final_candidate], "en")
    result.should_not be_nil
    result.not_nil!.status.failed?.should be_true
    File.exists?(final_candidate.to_s).should be_false
  ensure
    EasySubtitle::SubtitleCache.clear(video, "en") if video
    FileUtils.rm_rf(dir.to_s) if dir
  end
end
