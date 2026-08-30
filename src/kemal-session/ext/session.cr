# Lazy CSRF token access on the session.
#
# The CSRF middleware no longer creates a token (and with it a session store
# entry) for every request it sees. Instead the token is materialised the
# moment the application reads it, which keeps the documented usage
#
#     get "/form" do |env|
#       csrf_token = env.session.string("csrf")
#     end
#
# working while anonymous, cookie-less requests leave no trace in the store.
class Kemal::Session
  # :nodoc:
  # The request context this session was built from, if any. `Session` can also
  # be instantiated detached from a request (`Session.new(id)`), in which case
  # there is no context and no cookie to update.
  def context : HTTP::Server::Context?
    @context
  end

  # Returns the CSRF token of this session, creating and persisting one if it
  # does not exist yet.
  def csrf_token : String
    CSRF.token(self)
  end

  # Only the raising accessor is special cased. `string?` stays a pure
  # existence check: making it materialise the token would turn every
  # `session.string?("csrf")` probe into a write.
  def string(k : String) : String
    return csrf_token if k == CSRF::SESSION_KEY
    previous_def
  end
end
