require "spec"
require "../src/kemal-session"
require "file_utils"

Spec.before_each do
  sessions_path = File.join(Dir.current, "spec", "assets", "sessions")
  Dir.foreach(sessions_path) do |file|
    next if file == "."
    File.delete File.join(Dir.current, "spec", "assets", "sessions", file)
  end
end

def create_context(session_id : String)
  response = HTTP::Server::Response.new(MemoryIO.new)
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

Session.config.engine = Session::FileSystemEngine.new({:sessions_dir => "./spec/assets/sessions/"})
