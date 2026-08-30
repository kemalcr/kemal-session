require "./spec_helper"

describe "CSRF" do
  before_each do
    Kemal::Session.config.engine = Kemal::Session::MemoryEngine.new
    Kemal::Session.config.secret = "kemal_rocks"
    Kemal::Session.config.timeout = 1.hour
    Kemal::Session.config.gc_interval = 4.minutes
  end

  it "sends GETs to next handler" do
    handler = Kemal::Session::CSRF.new
    request = HTTP::Request.new("GET", "/")
    io_with_context = create_request_and_return_io(handler, request)
    client_response = HTTP::Client::Response.from_io(io_with_context, decompress: false)
    client_response.status_code.should eq 404
  end

  it "blocks POSTs without the token" do
    handler = Kemal::Session::CSRF.new
    request = HTTP::Request.new("POST", "/")
    io_with_context = create_request_and_return_io(handler, request)
    client_response = HTTP::Client::Response.from_io(io_with_context, decompress: false)
    client_response.status_code.should eq 403
  end

  it "allows POSTs with the correct token in FORM submit" do
    handler = Kemal::Session::CSRF.new
    current_token, cookie_header = render_form(handler)

    handler = Kemal::Session::CSRF.new
    request = HTTP::Request.new("POST", "/",
      body: "authenticity_token=cemal&hasan=lamec",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded",
                             "Cookie"       => cookie_header})
    io, context = process_request(handler, request)
    client_response = HTTP::Client::Response.from_io(io, decompress: false)
    client_response.status_code.should eq 403

    handler = Kemal::Session::CSRF.new
    request = HTTP::Request.new("POST", "/",
      body: "authenticity_token=#{current_token}&hasan=lamec",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded",
                             "Cookie"       => cookie_header})
    io, context = process_request(handler, request)
    client_response = HTTP::Client::Response.from_io(io, decompress: false)
    client_response.status_code.should eq 404
  end

  it "allows POSTs with the correct token in HTTP header" do
    handler = Kemal::Session::CSRF.new
    current_token, cookie_header = render_form(handler)

    handler = Kemal::Session::CSRF.new
    request = HTTP::Request.new("POST", "/",
      body: "hasan=lamec",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded",
                             "Cookie"       => cookie_header})
    io, context = process_request(handler, request)
    client_response = HTTP::Client::Response.from_io(io, decompress: false)
    client_response.status_code.should eq 403

    handler = Kemal::Session::CSRF.new
    request = HTTP::Request.new("POST", "/",
      body: "hasan=lamec",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded",
                             "Cookie"       => cookie_header,
                             "x-csrf-token" => current_token})
    io, context = process_request(handler, request)
    client_response = HTTP::Client::Response.from_io(io, decompress: false)
    client_response.status_code.should eq 404
  end

  it "allows POSTs to allowed route" do
    handler = Kemal::Session::CSRF.new(allowed_routes: ["/allowed"])
    request = HTTP::Request.new("POST", "/allowed/",
      body: "authenticity_token=cemal&hasan=lamec",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"})
    io, context = process_request(handler, request)
    client_response = HTTP::Client::Response.from_io(io, decompress: false)
    client_response.status_code.should eq 404
  end

  it "allows POSTs to route using wildcards" do
    handler = Kemal::Session::CSRF.new(allowed_routes: ["/everything/*"])
    request = HTTP::Request.new("POST", "/everything/here/and",
      body: "authenticity_token=cemal&hasan=lamec",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"})
    io, context = process_request(handler, request)
    client_response = HTTP::Client::Response.from_io(io, decompress: false)
    client_response.status_code.should eq 404
  end

  it "not allows POSTs to mismatched route using wildcards" do
    handler = Kemal::Session::CSRF.new(allowed_routes: ["/nothing/*"])
    request = HTTP::Request.new("POST", "/something/",
      body: "authenticity_token=cemal&hasan=lamec",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"})
    io, context = process_request(handler, request)
    client_response = HTTP::Client::Response.from_io(io, decompress: false)
    client_response.status_code.should eq 403
  end

  it "outputs error string" do
    handler = Kemal::Session::CSRF.new(error: "Oh no you have an error")
    request = HTTP::Request.new("POST", "/")
    io_with_context = create_request_and_return_io(handler, request)
    client_response = HTTP::Client::Response.from_io(io_with_context, decompress: false)
    client_response.status_code.should eq 403
    client_response.body.should eq "Oh no you have an error"
  end

  it "call an error proc with context" do
    handler = Kemal::Session::CSRF.new(error: ->myerrorhandler(HTTP::Server::Context))
    request = HTTP::Request.new("POST", "/")
    io_with_context = create_request_and_return_io(handler, request)
    client_response = HTTP::Client::Response.from_io(io_with_context, decompress: false)
    client_response.status_code.should eq 403
    client_response.body.should eq "Error from handler"
  end

  it "does not change the token when per_session is set" do
    handler = Kemal::Session::CSRF.new(per_session: true)
    first_token, cookie_header = render_form(handler, "/first")

    request = HTTP::Request.new("POST", "/second",
      body: "authenticity_token=#{first_token}",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded",
                             "Cookie"       => cookie_header})
    io, context = process_request(handler, request)
    context.session.string("csrf").should eq first_token
  end

  it "does not create sessions for anonymous safe requests" do
    handler = Kemal::Session::CSRF.new
    %w(GET HEAD OPTIONS TRACE).each do |method|
      50.times do
        create_request_and_return_io(handler, HTTP::Request.new(method, "/"))
      end
    end
    Kemal::Session.all.size.should eq 0
  end

  it "does not set any cookie on an anonymous GET" do
    handler = Kemal::Session::CSRF.new
    io = create_request_and_return_io(handler, HTTP::Request.new("GET", "/"))
    client_response = HTTP::Client::Response.from_io(io, decompress: false)
    client_response.headers.get?("Set-Cookie").should be_nil
  end

  it "creates the token lazily when the application reads it" do
    handler = Kemal::Session::CSRF.new
    io, _ = process_request_with_app(handler, HTTP::Request.new("GET", "/form")) do |env|
      env.response.print env.session.string("csrf")
    end
    client_response = HTTP::Client::Response.from_io(io, decompress: false)

    client_response.body.should_not be_empty
    Kemal::Session.all.size.should eq 1
    response_cookies(client_response)["authenticity_token"].value.should eq client_response.body
  end

  it "creates the token lazily through the csrf_token helper" do
    handler = Kemal::Session::CSRF.new
    io, _ = process_request_with_app(handler, HTTP::Request.new("GET", "/form")) do |env|
      env.response.print Kemal::Session::CSRF.token(env)
      env.response.print ":"
      env.response.print env.session.csrf_token
    end
    client_response = HTTP::Client::Response.from_io(io, decompress: false)

    first, second = client_response.body.split(":")
    first.should_not be_empty
    second.should eq first
    Kemal::Session.all.size.should eq 1
  end

  it "inherits secure, path and samesite from the session config" do
    previous_secure = Kemal::Session.config.secure
    previous_path = Kemal::Session.config.path
    previous_samesite = Kemal::Session.config.samesite
    Kemal::Session.config.secure = true
    Kemal::Session.config.path = "/app"
    Kemal::Session.config.samesite = HTTP::Cookie::SameSite::Strict

    begin
      handler = Kemal::Session::CSRF.new
      io, _ = process_request_with_app(handler, HTTP::Request.new("GET", "/form")) do |env|
        env.session.csrf_token
      end
      client_response = HTTP::Client::Response.from_io(io, decompress: false)

      cookie = response_cookies(client_response)["authenticity_token"]
      cookie.secure.should be_true
      cookie.path.should eq "/app"
      cookie.samesite.should eq HTTP::Cookie::SameSite::Strict
    ensure
      Kemal::Session.config.secure = previous_secure
      Kemal::Session.config.path = previous_path
      Kemal::Session.config.samesite = previous_samesite
    end
  end

  it "walks through the documented form rendering flow end to end" do
    handler = Kemal::Session::CSRF.new
    io, _ = process_request_with_app(handler, HTTP::Request.new("GET", "/form")) do |env|
      csrf_token = env.session.string("csrf")
      env.response.print %(<input type="hidden" name="authenticity_token" value="#{csrf_token}">)
    end
    get_response = HTTP::Client::Response.from_io(io, decompress: false)
    token = get_response.body[/value="([^"]+)"/, 1]
    Kemal::Session.all.size.should eq 1

    handler = Kemal::Session::CSRF.new
    request = HTTP::Request.new("POST", "/submit",
      body: "authenticity_token=#{token}&message=hello",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded",
                             "Cookie"       => request_cookie_header(get_response)})
    io, _ = process_request(handler, request)

    HTTP::Client::Response.from_io(io, decompress: false).status_code.should eq 404
    Kemal::Session.all.size.should eq 1
  end

  it "blocks POSTs carrying a wrong token" do
    handler = Kemal::Session::CSRF.new
    io, _ = process_request_with_app(handler, HTTP::Request.new("GET", "/form")) do |env|
      env.response.print env.session.string("csrf")
    end
    get_response = HTTP::Client::Response.from_io(io, decompress: false)
    cookie_header = request_cookie_header(get_response)

    ["", "nope", get_response.body + "extra", get_response.body.sub(get_response.body[0], 'z')].each do |wrong|
      handler = Kemal::Session::CSRF.new(per_session: true)
      request = HTTP::Request.new("POST", "/submit",
        body: "authenticity_token=#{wrong}",
        headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded",
                               "Cookie"       => cookie_header})
      io, _ = process_request(handler, request)
      HTTP::Client::Response.from_io(io, decompress: false).status_code.should eq 403
    end
  end

  it "keeps the token across requests when per_session is set" do
    handler = Kemal::Session::CSRF.new(per_session: true)
    io, _ = process_request_with_app(handler, HTTP::Request.new("GET", "/form")) do |env|
      env.response.print env.session.string("csrf")
    end
    get_response = HTTP::Client::Response.from_io(io, decompress: false)
    token = get_response.body
    cookie_header = request_cookie_header(get_response)

    2.times do
      handler = Kemal::Session::CSRF.new(per_session: true)
      request = HTTP::Request.new("POST", "/submit",
        body: "authenticity_token=#{token}",
        headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded",
                               "Cookie"       => cookie_header})
      io, context = process_request(handler, request)
      HTTP::Client::Response.from_io(io, decompress: false).status_code.should eq 404
      context.session.string("csrf").should eq token
    end
  end

  it "rotates the token after a successful request when per_session is not set" do
    handler = Kemal::Session::CSRF.new
    io, _ = process_request_with_app(handler, HTTP::Request.new("GET", "/form")) do |env|
      env.response.print env.session.string("csrf")
    end
    get_response = HTTP::Client::Response.from_io(io, decompress: false)
    token = get_response.body

    handler = Kemal::Session::CSRF.new
    request = HTTP::Request.new("POST", "/submit",
      body: "authenticity_token=#{token}",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded",
                             "Cookie"       => request_cookie_header(get_response)})
    io, context = process_request(handler, request)

    HTTP::Client::Response.from_io(io, decompress: false).status_code.should eq 404
    context.session.string("csrf").should_not eq token
  end

  it "keeps string? a pure existence check" do
    handler = Kemal::Session::CSRF.new
    io, _ = process_request_with_app(handler, HTTP::Request.new("GET", "/form")) do |env|
      env.response.print env.session.string?("csrf").nil?
    end
    client_response = HTTP::Client::Response.from_io(io, decompress: false)

    client_response.body.should eq "true"
    Kemal::Session.all.size.should eq 0
  end

  it "does not issue a CSRF cookie when the middleware is not installed" do
    io = IO::Memory.new
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(HTTP::Request.new("GET", "/form"), response)
    context.session.csrf_token
    response.close
    io.rewind
    client_response = HTTP::Client::Response.from_io(io, decompress: false)

    response_cookies(client_response)["authenticity_token"]?.should be_nil
  end

  it "uses the cookie settings of the handler serving the request" do
    custom_handler = Kemal::Session::CSRF.new(parameter_name: "_token", http_only: true)
    Kemal::Session::CSRF.new # a second handler must not clobber the first one's settings

    io, _ = process_request_with_app(custom_handler, HTTP::Request.new("GET", "/form")) do |env|
      env.response.print env.session.csrf_token
    end
    client_response = HTTP::Client::Response.from_io(io, decompress: false)

    cookies = response_cookies(client_response)
    cookies["authenticity_token"]?.should be_nil
    cookies["_token"].value.should eq client_response.body
    cookies["_token"].http_only.should be_true
  end

  it "re-issues the cookie when the token rotates" do
    handler = Kemal::Session::CSRF.new
    io, _ = process_request_with_app(handler, HTTP::Request.new("GET", "/form")) do |env|
      env.response.print env.session.string("csrf")
    end
    get_response = HTTP::Client::Response.from_io(io, decompress: false)

    handler = Kemal::Session::CSRF.new
    request = HTTP::Request.new("POST", "/submit",
      body: "authenticity_token=#{get_response.body}",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded",
                             "Cookie"       => request_cookie_header(get_response)})
    io, context = process_request_with_app(handler, request, &.response.print("ok"))
    post_response = HTTP::Client::Response.from_io(io, decompress: false)

    post_response.body.should eq "ok"
    rotated = context.session.string("csrf")
    rotated.should_not eq get_response.body
    response_cookies(post_response)["authenticity_token"].value.should eq rotated
  end

  it "rejects a token-less request whose session token equals the missing-token sentinel" do
    handler = Kemal::Session::CSRF.new
    io, context = process_request_with_app(handler, HTTP::Request.new("GET", "/form")) do |env|
      env.session.csrf_token
    end
    get_response = HTTP::Client::Response.from_io(io, decompress: false)
    Kemal::Session.config.engine.string(context.session.id, "csrf", "nothing")

    handler = Kemal::Session::CSRF.new
    request = HTTP::Request.new("POST", "/submit",
      body: "message=hello",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded",
                             "Cookie"       => request_cookie_header(get_response)})
    io, _ = process_request(handler, request)

    HTTP::Client::Response.from_io(io, decompress: false).status_code.should eq 403
  end

  it "does not create sessions for anonymous unsafe requests" do
    handler = Kemal::Session::CSRF.new
    %w(POST PUT PATCH DELETE).each do |method|
      20.times do
        request = HTTP::Request.new(method, "/",
          body: "authenticity_token=guess&message=hello",
          headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"})
        io = create_request_and_return_io(handler, request)
        HTTP::Client::Response.from_io(io, decompress: false).status_code.should eq 403
      end
    end
    Kemal::Session.all.size.should eq 0
  end

  it "does not hand out a session cookie on a POST that carries none" do
    handler = Kemal::Session::CSRF.new
    request = HTTP::Request.new("POST", "/",
      body: "authenticity_token=guess",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"})
    io = create_request_and_return_io(handler, request)
    client_response = HTTP::Client::Response.from_io(io, decompress: false)

    client_response.status_code.should eq 403
    client_response.headers.get?("Set-Cookie").should be_nil
  end

  it "does not create a session for an unsafe request with a forged session cookie" do
    handler = Kemal::Session::CSRF.new
    20.times do |i|
      request = HTTP::Request.new("POST", "/",
        body: "authenticity_token=guess",
        headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded",
                               "Cookie"       => "#{Kemal::Session.config.cookie_name}=forged#{i}--deadbeef"})
      io = create_request_and_return_io(handler, request)
      HTTP::Client::Response.from_io(io, decompress: false).status_code.should eq 403
    end
    Kemal::Session.all.size.should eq 0
  end

  it "supports the documented token endpoint flow for JavaScript clients" do
    handler = Kemal::Session::CSRF.new
    io, _ = process_request_with_app(handler, HTTP::Request.new("GET", "/csrf")) do |env|
      env.response.content_type = "application/json"
      env.response.print({token: env.session.csrf_token}.to_json)
    end
    csrf_response = HTTP::Client::Response.from_io(io, decompress: false)
    token = JSON.parse(csrf_response.body)["token"].as_s

    handler = Kemal::Session::CSRF.new
    request = HTTP::Request.new("POST", "/api/messages",
      body: %({"message":"hello"}),
      headers: HTTP::Headers{"Content-Type" => "application/json",
                             "Cookie"       => request_cookie_header(csrf_response),
                             "X-CSRF-Token" => token})
    io, _ = process_request_with_app(handler, request, &.response.print("created"))

    HTTP::Client::Response.from_io(io, decompress: false).body.should eq "created"
  end
end

def create_request_and_return_io(handler, request)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  handler.call(context)
  response.close
  io.rewind
  io
end

def process_request(handler, request)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  handler.call(context)
  response.close
  io.rewind
  {io, context}
end

def process_request_with_app(handler, request, &app : HTTP::Server::Context -> _)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  handler.next = ->(ctx : HTTP::Server::Context) { app.call(ctx); nil }
  handler.call(context)
  response.close
  io.rewind
  {io, context}
end

# Mimics the documented form rendering flow: a route reads the CSRF token
# while serving a safe request, which is what materialises it. Returns the
# token and the `Cookie` header a browser would send back.
def render_form(handler, path = "/")
  io, _ = process_request_with_app(handler, HTTP::Request.new("GET", path)) do |env|
    env.response.print env.session.string("csrf")
  end
  client_response = HTTP::Client::Response.from_io(io, decompress: false)
  {client_response.body, request_cookie_header(client_response)}
end

def response_cookies(client_response)
  HTTP::Cookies.from_server_headers(client_response.headers)
end

def request_cookie_header(client_response)
  response_cookies(client_response).map { |cookie| "#{cookie.name}=#{cookie.value}" }.join("; ")
end

def myerrorhandler(ctx : HTTP::Server::Context)
  "Error from handler"
end
