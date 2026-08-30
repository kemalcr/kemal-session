# Add the session to the context so it can be used
# like this:
# get "/" do |env|
#   env.session.int?("hi")
# end
class HTTP::Server::Context
  property! session : Kemal::Session
  property! flash : Kemal::Session::Flash

  # :nodoc:
  # The CSRF handler serving this request, if the middleware is installed. It
  # provides the cookie settings used when the CSRF token is materialised
  # lazily by the application.
  property csrf_handler : Kemal::Session::CSRF?

  def session
    @session ||= Kemal::Session.new(self)
    @session.not_nil!
  end

  def flash
    @flash ||= Kemal::Session::Flash.new(session)
    @flash.not_nil!
  end
end
