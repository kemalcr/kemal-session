class Session
  class Config
    INSTANCE = self.new

    @timeout : Time::Span
    @gc_interval : Time::Span
    @cookie_name : String
    @engine : Engine
    @secret_token : String
    property timeout, gc_interval, cookie_name, engine, secret_token

    @engine_set = false

    def engine_set?
      @engine_set
    end

    def engine=(e : Engine)
      @engine = e
      @engine_set = true
    end

    def initialize
      @timeout = Time::Span.new(1, 0, 0)
      @gc_interval = Time::Span.new(0, 4, 0)
      @cookie_name = "kemal_sessid"
      @engine = MemoryEngine.new
      @secret_token = ""
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
