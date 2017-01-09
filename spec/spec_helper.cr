require "spec"
require "json"
require "../src/kemal-session"
require "file_utils"

# Config Options
#
Session.config.engine = Session::MemoryEngine.new
Session.config.secret = "kemal_rocks"

# For testing cookie signing and for having a valid session
#
SESSION_SECRET = "b3c631c314c0bbca50c1b2843150fe33"
SESSION_ID     = SecureRandom.hex
SIGNED_SESSION = "#{SESSION_ID}--#{Session.sign_value(SESSION_ID)}"

def create_context(session_id : String)
  response = HTTP::Server::Response.new(IO::Memory.new)
  headers = HTTP::Headers.new

  # I would rather pass nil if no cookie should be created
  # but that throws an error
  unless session_id == ""
    Session.config.engine.create_session(session_id)

    cookies = HTTP::Cookies.new
    cookies << HTTP::Cookie.new(Session.config.cookie_name, Session.encode(session_id))
    cookies.add_request_headers(headers)
  end

  request = HTTP::Request.new("GET", "/", headers)
  return HTTP::Server::Context.new(request, response)
end

class User < Session::StorableObject
  JSON.mapping(
    id: Int32,
    name: String
  )

  def initialize(@id : Int32, @name : String)
  end

  def serialize
    return to_json
  end

  def self.unserialize(str : String)
    return User.from_json(str)
  end
end

class BadUser < Session::StorableObject
  property name

  def initialize(@name : String); end

  def serialize
    return @name
  end
end
