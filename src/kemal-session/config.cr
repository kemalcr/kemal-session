module Kemal
  class Session
    class Config
      INSTANCE = self.new

      @timeout : Time::Span
      @gc_interval : Time::Span
      @cookie_name : String
      @engine : Engine
      @secret : String
      @secure : Bool
      @domain : String?
      @path : String
      @samesite : Cookie::SameSite?
      property timeout, gc_interval, cookie_name, engine, secret, secure, domain, path, samesite

      def engine=(e : Engine)
        @engine = e
      end

      def initialize
        @timeout = 1.hours
        @gc_interval = 4.minutes
        @cookie_name = "kemal_sessid"
        @engine = MemoryEngine.new
        @secret = ""
        @secure = false
        @domain = nil
        @path = "/"
        @samesite = nil
      end
    end # Config

    def self.config(&)
      yield Config::INSTANCE
    end

    def self.config
      Config::INSTANCE
    end
  end # Session
  include HTTP
end
