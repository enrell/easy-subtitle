module EasySubtitle
  module CLI
    class ExtractCommand
      def initialize(@config : Config, @log : Log)
      end

      def run(args : Array(String)) : Nil
        remux = false

        parser = OptionParser.new do |p|
          p.banner = "Usage: easy-subtitle extract [OPTIONS] PATH"
          p.on("--remux", "Also remux to strip unwanted tracks") { remux = true }
        end
        parser.parse(args)

        path = args.last?
        unless path
          STDERR.puts parser
          return
        end

        videos = VideoScanner.scan(path, @config)
        if videos.empty?
          @log.warn "No video files found in: #{path}"
          return
        end

        @log.info "Found #{videos.size} video(s)"

        extractor = Extractor.new(@config, @log)
        remuxer = Remuxer.new(@config, @log) if remux

        total_extracted = 0
        videos.each do |video|
          begin
            extracted = extractor.extract(video)
            total_extracted += extracted.size
            remuxer.try(&.remux(video)) if remux
          rescue ex : Exception
            @log.error "Failed to process #{video.name}: #{ex.message}"
          end
        end

        @log.success "Extracted #{total_extracted} subtitle track(s) from #{videos.size} video(s)"
      end
    end
  end
end
