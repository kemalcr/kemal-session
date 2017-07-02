# Add the session to the context so it can be used
# like this:
# get "/" do |env|
#   env.session.int?("hi")
# end
class HTTP::Server::Context
  property! session : Kemal::Session

  def session
    @session ||= Kemal::Session.new(self)
    @session.not_nil!
  end
end
