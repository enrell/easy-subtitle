require "../../spec_helper"

class FailingRunner < EasySubtitle::AlassRunner
  def initialize(log : EasySubtitle::Log)
    super(log)
  end

  def sync(video_path : Path, sub_in : Path, sub_out : Path) : EasySubtitle::ShellResult
    raise EasySubtitle::ExternalToolError.new("alass", -1, "boom")
  end
end

describe EasySubtitle::SmartSync do
  # SmartSync requires alass and real files to test properly.
  # These specs test the classification logic via SyncResult.

  describe "SyncResult" do
    it "reports accepted status" do
      result = EasySubtitle::SyncResult.new(
        candidate_path: Path.new("/tmp/test.srt"),
        offset: 0.05,
        status: EasySubtitle::SyncStatus::Accepted,
      )
      result.accepted?.should be_true
    end

    it "reports drift status" do
      result = EasySubtitle::SyncResult.new(
        candidate_path: Path.new("/tmp/test.srt"),
        offset: 1.5,
        status: EasySubtitle::SyncStatus::Drift,
      )
      result.accepted?.should be_false
      result.status.drift?.should be_true
    end

    it "reports failed status" do
      result = EasySubtitle::SyncResult.new(
        candidate_path: Path.new("/tmp/test.srt"),
        status: EasySubtitle::SyncStatus::Failed,
      )
      result.accepted?.should be_false
      result.status.failed?.should be_true
    end
  end

  describe "#execute" do
    it "returns a failed result when a worker raises" do
      log = EasySubtitle::Log.new(colorize: false, io: IO::Memory.new)
      sync = EasySubtitle::SmartSync.new(FailingRunner.new(log), EasySubtitle::Config.default, log)
      video = EasySubtitle::VideoFile.new(path: Path.new("/tmp/video.mkv"), size: 0_i64)
      result_channel = Channel(EasySubtitle::SyncResult?).new(1)

      spawn do
        result_channel.send(sync.execute([Path.new("/tmp/test.en.1.srt")], video))
      end

      result = select
      when value = result_channel.receive
        value
      when timeout(1.second)
        fail "SmartSync.execute timed out waiting for worker results"
      end

      result.should_not be_nil
      result.not_nil!.status.failed?.should be_true
      result.not_nil!.alass_output.should contain "boom"
    end
  end
end
