module EasySubtitle
  module Spinner
    FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

    def self.run(label : String, io : IO = STDERR, &)
      running = true
      start = Time.instant

      spawn do
        i = 0
        while running
          elapsed = (Time.instant - start).total_seconds.to_i
          io.print "\r#{FRAMES[i % FRAMES.size]} #{label} (#{elapsed}s)"
          io.flush
          i += 1
          sleep 100.milliseconds
        end
      end

      begin
        yield
      ensure
        running = false
        Fiber.yield # let spinner fiber see the flag
        io.print "\r\e[2K"
        io.flush
      end
    end
  end
end
