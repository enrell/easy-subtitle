require "json"

module EasySubtitle
  module CLI
    class ScanCommand
      def initialize(@config : Config, @log : Log)
      end

      def run(args : Array(String)) : Nil
        json_output = false
        languages = @config.languages.dup

        parser = OptionParser.new do |p|
          p.banner = "Usage: easy-subtitle scan [OPTIONS] PATH"
          p.on("--json", "Output as JSON") { json_output = true }
          p.on("-l LANGS", "--languages LANGS", "Languages to check") do |l|
            languages = l.split(",").map(&.strip)
          end
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

        entries = videos.map { |video| build_coverage(video, languages) }

        if json_output
          print_json(entries, languages)
        else
          print_table(entries, languages)
        end
      end

      private def build_coverage(video : VideoFile, languages : Array(String)) : CoverageEntry
        entry = CoverageEntry.new(video)
        begin
          dir = video.directory

          languages.each do |lang|
            subs = [] of Path
            Dir.each_child(dir.to_s) do |name|
              if name.starts_with?(video.stem) && name.includes?(".#{lang}.") && name.ends_with?(".srt")
                subs << dir / name
              end
            end
            entry.subtitles[lang] = subs
          end
        rescue ex : File::Error
          @log.error "Failed to scan #{video.name}: #{ex.message}"
        end

        entry
      end

      private def print_table(entries : Array(CoverageEntry), languages : Array(String)) : Nil
        complete = entries.count(&.complete?(languages))
        total = entries.size

        puts "Subtitle Coverage Report"
        puts "=" * 60
        puts

        # Header
        header = String.build do |io|
          io << "%-40s" % "Video"
          languages.each { |l| io << " %4s" % l }
          io << "  Status"
        end
        puts header
        puts "-" * (42 + languages.size * 5 + 8)

        entries.each do |entry|
          line = String.build do |io|
            name = entry.video.name
            name = name[0...37] + "..." if name.size > 40
            io << "%-40s" % name
            languages.each do |lang|
              has = entry.has_language?(lang)
              io << (has ? "   ✓" : "   ✗")
            end
            io << (entry.complete?(languages) ? "  OK" : "  MISSING")
          end
          puts line
        end

        puts
        puts "#{complete}/#{total} videos have complete subtitle coverage"
      end

      private def print_json(entries : Array(CoverageEntry), languages : Array(String)) : Nil
        result = entries.map do |entry|
          subs = {} of String => Int32
          languages.each { |l| subs[l] = entry.subtitles[l]?.try(&.size) || 0 }
          {
            "video"     => entry.video.name,
            "complete"  => entry.complete?(languages),
            "subtitles" => subs,
          }
        end

        puts result.to_json
      end
    end
  end
end
