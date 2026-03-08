module EasySubtitle
  module CLI
    class CleanCommand
      def initialize(@config : Config, @log : Log)
      end

      def run(args : Array(String)) : Nil
        no_backup = false

        parser = OptionParser.new do |p|
          p.banner = "Usage: easy-subtitle clean [OPTIONS] PATH"
          p.on("--no-backup", "Don't create backup files") { no_backup = true }
        end
        parser.parse(args)

        path = args.last?
        unless path
          STDERR.puts parser
          return
        end

        srt_files = find_srt_files(path)
        if srt_files.empty?
          @log.warn "No SRT files found in: #{path}"
          return
        end

        total_removed = 0
        srt_files.each do |srt_path|
          begin
            removed = SrtCleaner.clean_file(srt_path, backup: !no_backup)
            if removed > 0
              @log.success "Cleaned #{srt_path.basename}: removed #{removed} ad block(s)"
              total_removed += removed
            end
          rescue ex : Exception
            @log.error "Failed to clean #{srt_path.basename}: #{ex.message}"
          end
        end

        @log.success "Total: removed #{total_removed} ad block(s) from #{srt_files.size} file(s)"
      end

      private def find_srt_files(path : String) : Array(Path)
        files = [] of Path

        if File.file?(path) && path.ends_with?(".srt")
          files << Path.new(path)
        elsif File.directory?(path)
          Dir.glob(File.join(path, "**", "*.srt")) do |f|
            files << Path.new(f)
          end
        end

        files
      end
    end
  end
end
