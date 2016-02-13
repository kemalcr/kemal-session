require "spec"
require "../src/kemal-session"
require "http"

Spec.before_each do
  fake_context = HTTP::Server::Context.new(HTTP::Request.new("hello", nil), HTTP::Server::Response.new("ha"))
  $session = Kemal::Session.new(fake_context)
end
