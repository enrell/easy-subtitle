module EasySubtitle
  class AlassRunner
    DEFAULT_TIMEOUT = 10.minutes

    def initialize(@log : Log, @timeout : Time::Span = DEFAULT_TIMEOUT)
    end

    def sync(video_path : Path, sub_in : Path, sub_out : Path) : ShellResult
      @log.debug "Running alass: #{video_path.basename} + #{sub_in.basename}"
      Spinner.run("Syncing #{sub_in.basename}") do
        Shell.run(
          "alass",
          [video_path.to_s, sub_in.to_s, sub_out.to_s],
          raise_on_error: false,
          timeout: @timeout
        )
      end
    end

    def available? : Bool
      !Shell.which("alass").nil?
    end
  end
end
