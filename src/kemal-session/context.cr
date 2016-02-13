class Session
  def self.id_from_context(context) : String | Nil
    if(c = context.request.cookies[Session.config.cookie_name]?)
      return c.value
    else
      return nil
    end
  end

  def update_context(context)
    c = HTTP::Cookies.new
    c << HTTP::Cookie.new(Session.config.cookie_name, @id, "/", Time.now.to_utc + Session.config.timeout) # to_utc: because of https://github.com/manastech/crystal/issues/2150
    c.add_response_headers context.response.headers
  end

end
