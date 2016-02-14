class Session
  class Config
    INSTANCE = self.new
    ENGINES  = ["filesystem"]

    @timeout      : Time::Span
    @gc_interval  : Time::Span
    @cookie_name  : String
    property timeout, gc_interval, cookie_name

    @engine       : String
    @sessions_dir : String
    getter sessions_dir, engine

    def initialize
      @timeout      = Time::Span.new(1, 0, 0)
      @gc_interval  = Time::Span.new(0, 4, 0)
      @cookie_name  = "kemal_sessid"
      @engine       = "filesystem"
      @sessions_dir = "./sessions/"
    end

    def sessions_dir=(v : String) : String
      raise ArgumentError.new("Session: Cannot write to directory #{v}") unless File.directory?(v) && File.writable?(v)
      @sessions_dir = v
    end

    def engine=(v : String) : String
      raise ArgumentError.new("Session: Unknown engine #{v}") unless ENGINES.includes? v
      @engine = v
    end
  end # Config

  def self.config
   yield Config::INSTANCE
  end 

  def self.config
    Config::INSTANCE
  end

end # Session
