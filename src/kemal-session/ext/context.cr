# Add the session to the context so it can be used
# like this:
# get "/" do |env|
#   env.session.int?("hi")
# end
class HTTP::Server::Context
  property! session : Kemal::Session
  property! flash : Kemal::Session::Flash

  def session
    @session ||= Kemal::Session.new(self)
    @session.not_nil!
  end

  def flash
    @flash ||= Kemal::Session::Flash.new(session)
    @flash.not_nil!
  end
end
