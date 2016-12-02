require "spec"
require "../src/kemal-session"
require "file_utils"

SESSION_SECRET = "b3c631c314c0bbca50c1b2843150fe33"
SESSION_ID     = SecureRandom.hex
SIGNED_SESSION = "#{SESSION_ID}--#{Session.sign_value(SESSION_ID, SESSION_SECRET)}"

def create_context(session_id : String)
  response = HTTP::Server::Response.new(IO::Memory.new)
  headers = HTTP::Headers.new

  # I would rather pass nil if no cookie should be created
  # but that throws an error
  unless session_id == ""
    cookies = HTTP::Cookies.new
    cookies << HTTP::Cookie.new(Session.config.cookie_name, session_id)
    cookies.add_request_headers(headers)
  end

  request = HTTP::Request.new("GET", "/", headers)
  return HTTP::Server::Context.new(request, response)
end

Session.config.engine = Session::MemoryEngine.new
Session.config.secret = "kemal_rocks"
