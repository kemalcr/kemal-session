class Session
  class GC
    def initialize
      spawn do
        loop do
          Session.config.engine.run_gc
          sleep(Session.config.gc_interval.total_seconds)
        end
      end
    end
  end
end
