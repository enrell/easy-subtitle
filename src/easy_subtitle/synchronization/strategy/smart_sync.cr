module EasySubtitle
  class SmartSync
    def initialize(@runner : AlassRunner, @config : Config, @log : Log)
    end

    def execute(candidates : Array(Path), video : VideoFile) : SyncResult?
      return nil if candidates.empty?

      channel = Channel(SyncResult).new(candidates.size)

      candidates.each do |candidate|
        spawn do
          result = begin
            sync_one(candidate, video)
          rescue ex : Exception
            SyncResult.new(
              candidate_path: candidate,
              status: SyncStatus::Failed,
              alass_output: ex.message || "Synchronization failed",
            )
          end
          channel.send(result)
        end
      end

      results = Array(SyncResult).new(candidates.size)
      candidates.size.times do
        results << channel.receive
      end

      @log.info "Smart sync: #{results.count(&.accepted?)} accepted, #{results.count(&.status.drift?)} drift, #{results.count(&.status.failed?)} failed"

      # Pick the accepted result with lowest offset
      accepted = results.select(&.accepted?)
      if accepted.empty?
        # Fall back to drift results sorted by offset
        drift = results.select(&.status.drift?).sort_by(&.offset)
        return drift.first? if drift.any?
        return results.first?
      end

      accepted.min_by(&.offset)
    end

    private def sync_one(candidate : Path, video : VideoFile) : SyncResult
      suffix = "_synced#{candidate.extension}"
      output_path = candidate.parent / "#{candidate.stem}#{suffix}"

      shell_result = @runner.sync(video.path, candidate, output_path)

      unless shell_result.exit_code == 0 && File.exists?(output_path)
        return SyncResult.new(
          candidate_path: candidate,
          status: SyncStatus::Failed,
          alass_output: shell_result.stderr,
        )
      end

      offset = OffsetCalculator.calculate(candidate, output_path)
      status = classify_offset(offset)

      SyncResult.new(
        candidate_path: candidate,
        output_path: output_path,
        offset: offset,
        status: status,
        alass_output: shell_result.stdout,
      )
    rescue ex : Exception
      SyncResult.new(
        candidate_path: candidate,
        status: SyncStatus::Failed,
        alass_output: ex.message || "Synchronization failed",
      )
    end

    private def classify_offset(offset : Float64) : SyncStatus
      if offset <= @config.accept_offset_threshold
        SyncStatus::Accepted
      elsif offset <= @config.reject_offset_threshold
        SyncStatus::Drift
      else
        SyncStatus::Failed
      end
    end
  end
end
