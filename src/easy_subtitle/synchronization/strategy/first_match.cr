module EasySubtitle
  class FirstMatch
    include SyncOneHelper

    def initialize(@runner : SyncBackend, @config : Config, @log : Log)
    end

    def execute(candidates : Array(Path), video : VideoFile) : SyncResult?
      return nil if candidates.empty?

      best_drift : SyncResult? = nil

      candidates.each do |candidate|
        result = sync_one(candidate, video)

        if result.accepted?
          @log.success "First match accepted: #{candidate.basename} (timing shift: #{result.offset.round(3)}s)"
          return result
        end

        if result.status.drift?
          if best_drift.nil? || result.offset < best_drift.not_nil!.offset
            best_drift = result
          end
        end
      end

      if drift = best_drift
        @log.warn "No perfect match, best drift: #{drift.candidate_path.basename} (timing shift: #{drift.offset.round(3)}s)"
        return drift
      end

      @log.error "All #{candidates.size} candidates failed"
      nil
    end
  end
end
