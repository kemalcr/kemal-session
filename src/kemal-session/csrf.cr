require "crypto/subtle"
require "digest/sha256"

module Kemal
  class Session
    # This middleware adds CSRF protection to your application.
    #
    # Returns 403 "Forbidden" unless the current CSRF token is submitted
    # with any non-GET/HEAD request.
    #
    # Without CSRF protection, your app is vulnerable to replay attacks
    # where an attacker can re-submit a form.
    #
    # The token is created *lazily*: safe requests (`GET`, `HEAD`, ...) never
    # create one on their own, otherwise every anonymous, cookie-less request
    # would write a new entry into the session store. The token is materialised
    # when the application actually asks for it (`env.session.string("csrf")`,
    # `env.session.csrf_token` or `Kemal::Session::CSRF.token(env)`) or when a
    # state changing request has to be verified.
    class CSRF < Kemal::Handler
      # Key the token is stored under within the session.
      SESSION_KEY = "csrf"

      # Number of random bytes used for a token.
      TOKEN_BYTES = 16

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

      # Returns the CSRF token of *session*, creating and persisting one only if
      # it does not exist yet. When the session belongs to an active request the
      # token is also handed to the client as a cookie.
      def self.token(session : Kemal::Session) : String
        # Read through the engine directly: `Session#string?` routes the CSRF key
        # back into this method and would recurse.
        if existing = Kemal::Session.config.engine.string?(session.id, SESSION_KEY)
          return existing
        end

        token = generate_token
        session.string(SESSION_KEY, token)
        issue_cookie(session, token)
        token
      end

      # :ditto:
      def self.token(context : HTTP::Server::Context) : String
        token(context.session)
      end

      # :nodoc:
      def self.generate_token : String
        Random::Secure.hex(TOKEN_BYTES)
      end

      # Hands *token* to the client, using the cookie settings of the handler that
      # is processing the current request. Nothing is sent when the session is
      # detached from a request or when no CSRF handler is installed, so an
      # application that never adds the middleware never sees the cookie.
      #
      # NOTE: response headers are already on the wire once the body has been
      # flushed, so a token materialised after that point is stored server side
      # but not sent as a cookie.
      # :nodoc:
      def self.issue_cookie(session : Kemal::Session, token : String) : Nil
        return unless context = session.context
        return unless handler = context.csrf_handler
        context.response.cookies << handler.build_cookie(token)
      end

      # The CSRF cookie inherits `secure`, `path`, `domain` and `samesite` from
      # the session configuration so that it is not sent over plaintext
      # connections when the session cookie isn't either.
      # :nodoc:
      def build_cookie(token : String) : HTTP::Cookie
        HTTP::Cookie.new(
          name: @parameter_name,
          value: token,
          expires: Time.utc + Kemal::Session.config.timeout,
          http_only: @http_only,
          secure: Kemal::Session.config.secure,
          path: Kemal::Session.config.path,
          domain: Kemal::Session.config.domain,
          samesite: @samesite || Kemal::Session.config.samesite,
        )
      end

      # Compares two tokens in constant time. Both sides are hashed first so the
      # comparison always runs over equally sized digests:
      # `Crypto::Subtle.constant_time_compare` bails out early when the sizes
      # differ, which would leak the token length.
      # :nodoc:
      def self.same_token?(current : String, submitted : String) : Bool
        Crypto::Subtle.constant_time_compare(
          Digest::SHA256.digest(current),
          Digest::SHA256.digest(submitted)
        )
      end

      def call(context)
        # Record which handler is serving this request so that a token
        # materialised further down the chain is shipped with this handler's
        # cookie settings rather than another instance's.
        context.csrf_handler = self

        return call_next(context) if exclude_match?(context)

        # Safe methods must not touch the session. Creating a token here would
        # let any anonymous request grow the session store without limit.
        return call_next(context) if @allowed_methods.includes?(context.request.method)

        # Never mint a token here either. A client that has none stored cannot
        # possibly submit a matching one, so creating it would only hand
        # anonymous requests a way to grow the session store, exactly like the
        # safe path above.
        if current_token = stored_token(context)
          # A missing token is kept as `nil` rather than folded into a sentinel
          # string, which would be accepted by a session whose token happens to
          # equal that sentinel.
          submitted = context.request.headers[@header]? || context.params.body[@parameter_name]?

          if submitted && self.class.same_token?(current_token, submitted)
            unless @per_session
              rotated = self.class.generate_token
              context.session.string(SESSION_KEY, rotated)
              context.response.cookies << build_cookie(rotated)
            end

            return call_next(context)
          end
        end

        context.response.status_code = 403
        if (error = @error) && !error.is_a?(String)
          context.response.print error.call(context)
        else
          context.response.print error
        end
      end

      # Returns the token stored for the client's session, without creating
      # anything. `context.session` is only dereferenced when the client
      # actually sent a session cookie: touching it otherwise mints a new id and
      # a `Set-Cookie`, which a cross-site POST could use to overwrite the
      # victim's session cookie.
      private def stored_token(context) : String?
        return nil unless context.request.cookies[Kemal::Session.config.cookie_name]?
        Kemal::Session.config.engine.string?(context.session.id, SESSION_KEY)
      end
    end
  end
end
