# @TODO would it be better to not wrap this inside the class?
# What difference does it make?

class Session

  spawn do
    loop do
      case Session.config.engine
      when "filesystem"
        Session.e_filesystem_gc
      end
      sleep(Session.config.gc_interval.total_seconds)
    end
  end

end


