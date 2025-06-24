module Kemal
  class Session
    class GC
      def initialize
        spawn do
          loop do
            Session.config.engine.run_gc
            sleep(Session.config.gc_interval)
          end
        end
      end
    end
  end
end
