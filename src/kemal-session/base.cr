require "secure_random"

class Session
  @id : String

  def initialize(context : HTTP::Server::Context)
    Session.config.set_default_engine unless Session.config.engine_set?
    id = context.request.cookies[Session.config.cookie_name]?.try &.value
    if id && id.size == 32
      # valid
    else
      # new or invalid
      id = SecureRandom.hex
    end

    context.response.cookies << HTTP::Cookie.new(name: Session.config.cookie_name, value: id, expires: Time.now.to_utc + Session.config.timeout, http_only: true)
    @id = id
  end
end
