require "uri"
require "secure_random"
require "openssl/hmac"
require "openssl/sha1"

class Session
  @id : String

  def initialize(context : HTTP::Server::Context)
    Session.config.set_default_engine unless Session.config.engine_set?
    id = context.request.cookies[Session.config.cookie_name]?.try &.value
    valid = false
    if id
      if !Session.config.secret_token.nil?
        t_id = URI.unescape(id)
        parts = t_id.split("--")
        if parts.size == 2
          new_val = self.class.sign_value(parts[0])
          id = parts[0]
          valid = true if new_val == parts[1] && parts[0].size == 32
        end
      elsif id.size == 32
        valid = true
      end
    end

    if !valid
      # new or invalid
      id = SecureRandom.hex
    end

    context.response.cookies << HTTP::Cookie.new(
                                  name: Session.config.cookie_name, 
                                  value: (Session.config.secret_token.nil? ? id.as(String) : self.class.encode(id.as(String))),
                                  expires: Time.now.to_utc + Session.config.timeout, 
                                  http_only: true
                                )
    @id = id.as(String)
    start_gc
  end

  # :nodoc:
  # id is the session_id that were signing.
  def self.sign_value(id : String, secret = Session.config.secret_token.as(String))
    OpenSSL::HMAC.hexdigest(:sha1, secret, id)
  end

  def self.encode(id : String)
    "#{id}--#{sign_value(id)}"
  end

  def start_gc
    spawn do
      loop do
        Session.config.engine.run_gc
        sleep(Session.config.gc_interval.total_seconds)
      end
    end
  end
end
