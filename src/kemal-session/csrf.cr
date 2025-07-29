module Kemal
  class Session
    # This middleware adds CSRF protection to your application.
    #
    # Returns 403 "Forbidden" unless the current CSRF token is submitted
    # with any non-GET/HEAD request.
    #
    # Without CSRF protection, your app is vulnerable to replay attacks
    # where an attacker can re-submit a form.
    class CSRF < Kemal::Handler
      def initialize(
        @header = "X_CSRF_TOKEN",
        @allowed_methods = %w(GET HEAD OPTIONS TRACE),
        @parameter_name = "authenticity_token",
        @error : String | (HTTP::Server::Context -> String) = "Forbidden (CSRF)",
        @allowed_routes = [] of String,
        @http_only : Bool = false,
        @samesite : HTTP::Cookie::SameSite? = nil,
	@per_session : Bool = false,
      )
        setup
      end

      def setup
        @allowed_routes.each do |path|
          class_name = {{@type.name}}
          %w(GET HEAD OPTIONS TRACE PUT POST).each do |method|
            @@exclude_routes_tree.add "#{class_name}/#{method}#{path}", "/#{method}#{path}"
          end
        end
      end

      def call(context)
        return call_next(context) if exclude_match?(context)
        unless context.session.string?("csrf")
          csrf_token = Random::Secure.hex(16)
          context.session.string("csrf", csrf_token)
          context.response.cookies << HTTP::Cookie.new(
            name: @parameter_name,
            value: csrf_token,
            expires: Time.local.to_utc + Kemal::Session.config.timeout,
            http_only: @http_only,
            samesite: @samesite,
          )
        end

        return call_next(context) if @allowed_methods.includes?(context.request.method)
        req = context.request
        submitted = if req.headers[@header]?
                      req.headers[@header]
                    elsif context.params.body[@parameter_name]?
                      context.params.body[@parameter_name]
                    else
                      "nothing"
                    end
        current_token = context.session.string("csrf")
        if current_token == submitted
          context.session.string("csrf", Random::Secure.hex(16)) unless @per_session

          return call_next(context)
        else
          context.response.status_code = 403
          if (error = @error) && !error.is_a?(String)
            context.response.print error.call(context)
          else
            context.response.print error
          end
        end
      end
    end
  end
end
