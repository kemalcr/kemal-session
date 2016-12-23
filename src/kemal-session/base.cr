require "uri"
require "secure_random"
require "openssl/hmac"
require "openssl/sha1"

class Session
  getter id

  @id : String
  @context : HTTP::Server::Context?

  def initialize(ctx : HTTP::Server::Context)
    Session.config.set_default_engine unless Session.config.engine_set?
    id = ctx.request.cookies[Session.config.cookie_name]?.try &.value
    valid = false
    if id
      parts = URI.unescape(id).split("--")
      if parts.size == 2
        new_val = self.class.sign_value(parts[0])
        id = parts[0]
        valid = true if new_val == parts[1] && parts[0].size == 32
      end
    end

    if id.nil? || !valid
      id = SecureRandom.hex
      Session.config.engine.create_session(id)
    end

    ctx.response.cookies << HTTP::Cookie.new(
      name: Session.config.cookie_name,
      value: self.class.encode(id),
      expires: Time.now.to_utc + Session.config.timeout,
      http_only: true,
      secure: Session.config.secure
    )
    @id      = id
    @context = ctx
  end

  # When initializing a Session with a string, it's disassociated
  # with an active request and response being handled by kemal. A
  # dummy Context is created and Session skips the validation
  # check on the session_id
  #
  def initialize(id : String)
    @id      = id
    @context = nil
  end

  # Removes a session from storage
  #
  def self.destroy(id : String)
    Session.config.engine.destroy_session(id)
  end

  # Invalidates the session by removing it from storage so that its
  # no longer tracked. If the session is being destroyed in the
  # context of an active request being processed by kemal, the session
  # cookie will be emptied.
  #
  def destroy
    if context = @context 
      context.response.cookies[Session.config.cookie_name].value = ""
    end
    Session.destroy(@id)
  end

  # Destroys all of the sessions stored in the storage engine
  #
  def self.destroy_all
    Session.config.engine.destroy_all_sessions
  end

  # Retrieves all sessions from session storage as an Array.
  # This will return all sessions in storage and could result
  # in a lot of memory usage. Use with caution. If something more
  # memory efficient is needed, use `Session.each`
  #
  def self.all
    Session.config.engine.all_sessions
  end

  # Enumerates through each session stored. Please read carefully
  # each storage engine with regard to how this method is implemented
  # some may dump all sessions in memory before iterating through
  # them.
  #
  def self.each
    Session.config.engine.each_session do |session|
      yield session
    end
  end

  # Retrieves a single session
  #
  def self.get(id : String)
    Session.config.engine.get_session(id)
  end

  # :nodoc:
  # id is the session_id that were signing.
  def self.sign_value(id : String, secret = Session.config.secret)
    raise SecretRequiredException.new if secret == ""
    OpenSSL::HMAC.hexdigest(:sha1, secret, id)
  end

  def self.encode(id : String)
    "#{id}--#{sign_value(id)}"
  end

  class SecretRequiredException < Exception
    def initialize
      error_message = <<-ERROR
              Please set your session secret within your config via

              Session.config do |config|
                Session.config.secret = \"my_super_secret\"
              end

              or

              Session.config.secret = \"my_super_secret\"
              ERROR
      super error_message
    end
  end
end
