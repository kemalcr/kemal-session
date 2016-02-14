# @TODO would it be better to not wrap this inside the class?
# What difference does it make?

class Session

  spawn do
    loop do
      Session.config.engine.run_gc
      sleep(Session.config.gc_interval.total_seconds)
    end
  end

end


