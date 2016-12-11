class Session
  class Config
    INSTANCE = self.new

    @timeout : Time::Span
    @gc_interval : Time::Span
    @cookie_name : String
    @engine : Engine
    @secret : String
    property timeout, gc_interval, cookie_name, engine, secret

    @engine_set = false

    def engine_set?
      @engine_set
    end

    def engine=(e : Engine)
      @engine = e
      @engine_set = true
    end

    def initialize
      @timeout = 1.hours
      @gc_interval = 4.minutes
      @cookie_name = "kemal_sessid"
      @engine = MemoryEngine.new
      @secret = ""
    end

    def set_default_engine
      Session.config.engine = MemoryEngine.new
    end
  end # Config

  def self.config
    yield Config::INSTANCE
  end

  def self.config
    Config::INSTANCE
  end
end # Session
