# Add the session to the context so it can be used
# like this:
# get "/" do |env|
#   env.session.int?("hi")
# end

class HTTP::Server::Context
  property! session
end

class SessionHandler < HTTP::Handler
  getter session

  def call(context)
    context.session = Session.start(context)
    call_next context
  end
end

Kemal.config.add_handler SessionHandler.new
