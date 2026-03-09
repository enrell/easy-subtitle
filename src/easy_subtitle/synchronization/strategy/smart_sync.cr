module EasySubtitle
  class SmartSync
    include SyncOneHelper

    def initialize(@runner : SyncBackend, @config : Config, @log : Log)
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
              sync_output: ex.message || "Synchronization failed",
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

      accepted = results.select(&.accepted?)
      if accepted.empty?
        drift = results.select(&.status.drift?)
        return best_result(drift) if drift.any?
        return best_result(results) if results.any?
        return nil
      end

      best_result(accepted)
    end

    private def best_result(results : Array(SyncResult)) : SyncResult
      results.max_by do |result|
        {
          status_rank(result.status),
          candidate_download_count(result.candidate_path),
          -result.offset,
        }
      end
    end

    private def candidate_download_count(path : Path) : Int64
      SubtitleFiles.candidate_download_count(path.basename)
    end

    private def status_rank(status : SyncStatus) : Int32
      case status
      when .accepted?
        2
      when .drift?
        1
      else
        0
      end
    end
  end
end
